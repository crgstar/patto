import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from './auth'
import axios from 'axios'

// axiosをモック化
vi.mock('axios', () => {
  const mockAxios = {
    post: vi.fn(),
    get: vi.fn(),
    delete: vi.fn(),
    defaults: {
      headers: {
        common: {}
      }
    },
    create: vi.fn(() => mockAxios)
  }
  return {
    default: mockAxios
  }
})

describe('Auth Store', () => {
  let store

  beforeEach(() => {
    // 各テスト前にPiniaをリセット
    setActivePinia(createPinia())
    store = useAuthStore()

    // localStorageをモック化
    global.localStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    }

    // axiosのモックをリセット
    vi.clearAllMocks()
  })

  describe('初期状態', () => {
    it('tokenがnullであること', () => {
      expect(store.token).toBeNull()
    })

    it('userがnullであること', () => {
      expect(store.user).toBeNull()
    })

    it('loadingがfalseであること', () => {
      expect(store.loading).toBe(false)
    })

    it('errorがnullであること', () => {
      expect(store.error).toBeNull()
    })

    it('isAuthenticatedがfalseであること', () => {
      expect(store.isAuthenticated).toBe(false)
    })
  })

  describe('login', () => {
    it('成功時にトークンとユーザー情報を保存すること', async () => {
      const mockResponse = {
        data: {
          token: 'test-token',
          user: { id: 1, email: 'test@example.com' }
        }
      }
      axios.post.mockResolvedValueOnce(mockResponse)

      const result = await store.login('test@example.com', 'password')

      expect(result).toBe(true)
      expect(store.token).toBe('test-token')
      expect(store.user).toEqual({ id: 1, email: 'test@example.com' })
      expect(localStorage.setItem).toHaveBeenCalledWith('token', 'test-token')
      expect(axios.defaults.headers.common['Authorization']).toBe('Bearer test-token')
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('失敗時にエラーメッセージを設定すること', async () => {
      const mockError = {
        response: {
          data: {
            error: 'Invalid email or password'
          }
        }
      }
      axios.post.mockRejectedValueOnce(mockError)

      const result = await store.login('test@example.com', 'wrong-password')

      expect(result).toBe(false)
      expect(store.token).toBeNull()
      expect(store.user).toBeNull()
      expect(store.error).toBe('Invalid email or password')
      expect(store.loading).toBe(false)
    })

    it('レスポンスにエラーがない場合はデフォルトメッセージを使用すること', async () => {
      axios.post.mockRejectedValueOnce(new Error('Network Error'))

      const result = await store.login('test@example.com', 'password')

      expect(result).toBe(false)
      expect(store.error).toBe('ログインに失敗しました')
    })
  })

  describe('signup', () => {
    it('成功時にトークンとユーザー情報を保存すること', async () => {
      const mockResponse = {
        data: {
          token: 'new-token',
          user: { id: 2, email: 'newuser@example.com' }
        }
      }
      axios.post.mockResolvedValueOnce(mockResponse)

      const result = await store.signup('newuser@example.com', 'password123', 'password123')

      expect(result).toBe(true)
      expect(store.token).toBe('new-token')
      expect(store.user).toEqual({ id: 2, email: 'newuser@example.com' })
      expect(localStorage.setItem).toHaveBeenCalledWith('token', 'new-token')
      expect(axios.defaults.headers.common['Authorization']).toBe('Bearer new-token')
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('失敗時にエラーメッセージを設定すること', async () => {
      const mockError = {
        response: {
          data: {
            errors: ['Email has already been taken', 'Password is too short']
          }
        }
      }
      axios.post.mockRejectedValueOnce(mockError)

      const result = await store.signup('test@example.com', 'short', 'short')

      expect(result).toBe(false)
      expect(store.token).toBeNull()
      expect(store.user).toBeNull()
      expect(store.error).toBe('Email has already been taken, Password is too short')
      expect(store.loading).toBe(false)
    })

    it('レスポンスにエラーがない場合はデフォルトメッセージを使用すること', async () => {
      axios.post.mockRejectedValueOnce(new Error('Network Error'))

      const result = await store.signup('test@example.com', 'password', 'password')

      expect(result).toBe(false)
      expect(store.error).toBe('サインアップに失敗しました')
    })
  })

  describe('logout', () => {
    it('トークンとユーザー情報をクリアすること', async () => {
      // 事前にログイン状態にする
      store.token = 'test-token'
      store.user = { id: 1, email: 'test@example.com' }
      axios.defaults.headers.common['Authorization'] = 'Bearer test-token'

      axios.delete.mockResolvedValueOnce({})

      await store.logout()

      expect(store.token).toBeNull()
      expect(store.user).toBeNull()
      expect(localStorage.removeItem).toHaveBeenCalledWith('token')
      expect(axios.defaults.headers.common['Authorization']).toBeUndefined()
    })

    it('APIエラーが発生してもローカルの状態をクリアすること', async () => {
      store.token = 'test-token'
      store.user = { id: 1, email: 'test@example.com' }

      axios.delete.mockRejectedValueOnce(new Error('API Error'))

      await store.logout()

      expect(store.token).toBeNull()
      expect(store.user).toBeNull()
      expect(localStorage.removeItem).toHaveBeenCalledWith('token')
    })
  })

  describe('fetchCurrentUser', () => {
    it('トークンがない場合はfalseを返すこと', async () => {
      store.token = null

      const result = await store.fetchCurrentUser()

      expect(result).toBe(false)
      expect(axios.get).not.toHaveBeenCalled()
    })

    it('成功時にユーザー情報を取得すること', async () => {
      store.token = 'valid-token'
      const mockResponse = {
        data: {
          user: { id: 1, email: 'test@example.com' }
        }
      }
      axios.get.mockResolvedValueOnce(mockResponse)

      const result = await store.fetchCurrentUser()

      expect(result).toBe(true)
      expect(store.user).toEqual({ id: 1, email: 'test@example.com' })
      expect(axios.defaults.headers.common['Authorization']).toBe('Bearer valid-token')
      expect(store.loading).toBe(false)
    })

    it('失敗時にトークンとユーザー情報をクリアすること', async () => {
      store.token = 'invalid-token'
      store.user = { id: 1, email: 'test@example.com' }

      axios.get.mockRejectedValueOnce(new Error('Unauthorized'))

      const result = await store.fetchCurrentUser()

      expect(result).toBe(false)
      expect(store.token).toBeNull()
      expect(store.user).toBeNull()
      expect(localStorage.removeItem).toHaveBeenCalledWith('token')
      expect(axios.defaults.headers.common['Authorization']).toBeUndefined()
      expect(store.loading).toBe(false)
    })
  })

  describe('isAuthenticated', () => {
    it('トークンがある場合はtrueを返すこと', () => {
      store.token = 'test-token'
      expect(store.isAuthenticated).toBe(true)
    })

    it('トークンがない場合はfalseを返すこと', () => {
      store.token = null
      expect(store.isAuthenticated).toBe(false)
    })
  })
})
