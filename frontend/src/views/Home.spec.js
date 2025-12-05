import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createMemoryHistory } from 'vue-router'
import Home from './Home.vue'
import { useAuthStore } from '@/stores/auth'
import { useStickyStore } from '@/stores/sticky'

// axiosをモック化
vi.mock('axios', () => {
  const mockAxios = {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
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

describe('Home.vue', () => {
  let router
  let pinia

  beforeEach(() => {
    pinia = createPinia()
    setActivePinia(pinia)

    router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/', component: Home },
        { path: '/login', component: { template: '<div>Login</div>' } }
      ]
    })

    // localStorageをモック化
    global.localStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    }

    // window.confirmをモック化
    global.confirm = vi.fn(() => true)

    vi.clearAllMocks()
  })

  describe('認証チェック', () => {
    it('ログインしていない場合はログインページにリダイレクト', async () => {
      const authStore = useAuthStore()
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(false)
      const pushSpy = vi.spyOn(router, 'push')

      mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      expect(authStore.fetchCurrentUser).toHaveBeenCalled()
      expect(pushSpy).toHaveBeenCalledWith('/login')
    })

    it('ログインしている場合はホーム画面を表示', async () => {
      const authStore = useAuthStore()
      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      expect(wrapper.text()).toContain('test@example.com')
    })
  })

  describe('Sticky一覧表示', () => {
    it('Sticky一覧を取得して表示すること', async () => {
      const authStore = useAuthStore()
      const stickyStore = useStickyStore()

      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(stickyStore, 'fetchStickies').mockResolvedValue()

      stickyStore.stickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 },
        { id: 2, type: 'Sticky', title: 'Test 2', content: 'Content 2', position: 2 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      expect(stickyStore.fetchStickies).toHaveBeenCalled()

      // inputとtextareaの値を確認
      const titleInput1 = wrapper.find('[data-testid="sticky-1-title"]')
      const titleInput2 = wrapper.find('[data-testid="sticky-2-title"]')

      expect(titleInput1.element.value).toBe('Test 1')
      expect(titleInput2.element.value).toBe('Test 2')
    })

    it('Stickyがない場合は空の状態を表示すること', async () => {
      const authStore = useAuthStore()
      const stickyStore = useStickyStore()

      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(stickyStore, 'fetchStickies').mockResolvedValue()

      stickyStore.stickies = []

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      expect(wrapper.text()).toContain('付箋がありません')
    })
  })

  describe('Sticky作成', () => {
    it('新しいStickyを作成できること', async () => {
      const authStore = useAuthStore()
      const stickyStore = useStickyStore()

      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(stickyStore, 'fetchStickies').mockResolvedValue()
      vi.spyOn(stickyStore, 'createSticky').mockResolvedValue(true)

      stickyStore.stickies = []

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      // 「新しい付箋」ボタンをクリック
      const createButton = wrapper.find('[data-testid="create-sticky-button"]')
      expect(createButton.exists()).toBe(true)

      await createButton.trigger('click')
      await flushPromises()

      expect(stickyStore.createSticky).toHaveBeenCalled()
    })
  })

  describe('Sticky更新', () => {
    it('Stickyのタイトルと内容を更新できること', async () => {
      const authStore = useAuthStore()
      const stickyStore = useStickyStore()

      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(stickyStore, 'fetchStickies').mockResolvedValue()
      vi.spyOn(stickyStore, 'updateSticky').mockResolvedValue(true)

      stickyStore.stickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      // タイトル入力欄を見つけて変更
      const titleInput = wrapper.find('[data-testid="sticky-1-title"]')
      await titleInput.setValue('Updated Title')
      await titleInput.trigger('blur')
      await flushPromises()

      expect(stickyStore.updateSticky).toHaveBeenCalledWith(1, expect.objectContaining({
        title: 'Updated Title'
      }))
    })
  })

  describe('Sticky削除', () => {
    it('Stickyを削除できること', async () => {
      const authStore = useAuthStore()
      const stickyStore = useStickyStore()

      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(stickyStore, 'fetchStickies').mockResolvedValue()
      vi.spyOn(stickyStore, 'deleteSticky').mockResolvedValue(true)

      stickyStore.stickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      // 削除ボタンをクリック
      const deleteButton = wrapper.find('[data-testid="delete-sticky-1"]')
      await deleteButton.trigger('click')
      await flushPromises()

      expect(stickyStore.deleteSticky).toHaveBeenCalledWith(1)
    })
  })

  describe('ログアウト', () => {
    it('ログアウトボタンをクリックするとログアウトしてログインページにリダイレクト', async () => {
      const authStore = useAuthStore()
      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(authStore, 'logout').mockResolvedValue()
      const pushSpy = vi.spyOn(router, 'push')

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      const buttons = wrapper.findAll('button')
      const logoutButton = buttons.find(b => b.text() === 'ログアウト')
      await logoutButton.trigger('click')
      await flushPromises()

      expect(authStore.logout).toHaveBeenCalled()
      expect(pushSpy).toHaveBeenCalledWith('/login')
    })
  })
})
