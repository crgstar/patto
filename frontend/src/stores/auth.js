import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import apiClient from '@/lib/apiClient'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || null)
  const user = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const isAuthenticated = computed(() => !!token.value)

  // ログイン
  const login = async (email, password) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post('/login', {
        email,
        password
      })

      token.value = response.data.token
      user.value = response.data.user
      localStorage.setItem('token', response.data.token)
      apiClient.defaults.headers.common['Authorization'] = `Bearer ${response.data.token}`

      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'ログインに失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // サインアップ
  const signup = async (email, password, password_confirmation) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post('/signup', {
        user: {
          email,
          password,
          password_confirmation
        }
      })

      token.value = response.data.token
      user.value = response.data.user
      localStorage.setItem('token', response.data.token)
      apiClient.defaults.headers.common['Authorization'] = `Bearer ${response.data.token}`

      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.join(', ') || 'サインアップに失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // ログアウト
  const logout = async () => {
    try {
      await apiClient.delete('/logout')
    } catch (err) {
      console.error('ログアウトエラー:', err)
    }

    token.value = null
    user.value = null
    localStorage.removeItem('token')
    delete apiClient.defaults.headers.common['Authorization']
  }

  // 現在のユーザー情報を取得
  const fetchCurrentUser = async () => {
    if (!token.value) return false

    loading.value = true

    try {
      apiClient.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
      const response = await apiClient.get('/current_user')
      user.value = response.data.user
      return true
    } catch (err) {
      // トークンが無効な場合はクリア
      token.value = null
      user.value = null
      localStorage.removeItem('token')
      delete apiClient.defaults.headers.common['Authorization']
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    token,
    user,
    loading,
    error,
    isAuthenticated,
    login,
    signup,
    logout,
    fetchCurrentUser
  }
})
