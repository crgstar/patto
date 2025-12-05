import { defineStore } from 'pinia'
import { ref } from 'vue'
import apiClient from '@/lib/apiClient'

export const useStickyStore = defineStore('sticky', () => {
  const stickies = ref([])
  const loading = ref(false)
  const error = ref(null)

  // Sticky一覧を取得
  const fetchStickies = async () => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.get('/stickies')
      stickies.value = response.data.stickies
    } catch (err) {
      error.value = err.response?.data?.error || 'Sticky一覧の取得に失敗しました'
    } finally {
      loading.value = false
    }
  }

  // Stickyを作成
  const createSticky = async (stickyData) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post('/stickies', {
        sticky: stickyData
      })

      stickies.value.push(response.data.sticky)
      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'Stickyの作成に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Stickyを更新
  const updateSticky = async (id, stickyData) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.patch(`/stickies/${id}`, {
        sticky: stickyData
      })

      const index = stickies.value.findIndex(s => s.id === id)
      if (index !== -1) {
        stickies.value[index] = response.data.sticky
      }

      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'Stickyの更新に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Stickyを削除（論理削除）
  const deleteSticky = async (id) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.delete(`/stickies/${id}`)

      stickies.value = stickies.value.filter(s => s.id !== id)
      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'Stickyの削除に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Stickyを並び替え
  const reorderStickies = async (reorderedStickies) => {
    loading.value = true
    error.value = null

    try {
      // positionを更新
      const updates = reorderedStickies.map((sticky, index) => ({
        id: sticky.id,
        position: index + 1
      }))

      await apiClient.patch('/stickies/reorder', {
        stickies: updates
      })

      // ローカルステートを更新
      stickies.value = reorderedStickies.map((sticky, index) => ({
        ...sticky,
        position: index + 1
      }))

      return true
    } catch (err) {
      error.value = err.response?.data?.error || '並び替えに失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    stickies,
    loading,
    error,
    fetchStickies,
    createSticky,
    updateSticky,
    deleteSticky,
    reorderStickies
  }
})
