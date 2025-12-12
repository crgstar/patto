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

// GridLayoutをモック化
vi.mock('@/components/GridLayout.vue', () => ({
  default: {
    name: 'GridLayout',
    props: ['layout'],
    template: `
      <div class="grid-layout">
        <div v-for="item in layout" :key="item.i" class="grid-item">
          <slot name="item" :item="item.sticky" />
        </div>
      </div>
    `
  }
}))

// DropdownMenuをモック化
vi.mock('@/components/ui/dropdown-menu', () => ({
  DropdownMenu: { name: 'DropdownMenu', template: '<div><slot /></div>' },
  DropdownMenuTrigger: { name: 'DropdownMenuTrigger', template: '<div><slot /></div>' },
  DropdownMenuContent: { name: 'DropdownMenuContent', template: '<div><slot /></div>' },
  DropdownMenuItem: { name: 'DropdownMenuItem', template: '<div @click="$emit(\'click\')"><slot /></div>' },
  DropdownMenuLabel: { name: 'DropdownMenuLabel', template: '<div><slot /></div>' },
  DropdownMenuSeparator: { name: 'DropdownMenuSeparator', template: '<div />' }
}))

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
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1, x: 0, y: 0, width: 1, height: 1 },
        { id: 2, type: 'Sticky', title: 'Test 2', content: 'Content 2', position: 2, x: 1, y: 0, width: 1, height: 1 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      expect(stickyStore.fetchStickies).toHaveBeenCalled()

      // タイトルが表示されていることを確認
      expect(wrapper.text()).toContain('Test 1')
      expect(wrapper.text()).toContain('Test 2')
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
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1, x: 0, y: 0, width: 1, height: 1 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      // textareaの値を直接変更
      const contentTextarea = wrapper.find('[data-testid="sticky-1-content"]')
      await contentTextarea.setValue('Updated Content')
      await contentTextarea.trigger('blur')
      await flushPromises()

      expect(stickyStore.updateSticky).toHaveBeenCalledWith(1, expect.objectContaining({
        content: 'Updated Content'
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
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1, x: 0, y: 0, width: 1, height: 1 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      // deleteSticky関数を直接呼び出す
      await wrapper.vm.deleteSticky(1)
      await flushPromises()

      // ダイアログが開いていることを確認
      expect(wrapper.vm.deleteDialogOpen).toBe(true)
      expect(wrapper.vm.deleteTargetId).toBe(1)
      expect(wrapper.vm.deleteTargetType).toBe('sticky')

      // 削除確認
      await wrapper.vm.confirmDelete()
      await flushPromises()

      expect(stickyStore.deleteSticky).toHaveBeenCalledWith(1)
      expect(wrapper.vm.deleteDialogOpen).toBe(false)
    })

    it('削除ダイアログでキャンセルを選択すると削除されないこと', async () => {
      const authStore = useAuthStore()
      const stickyStore = useStickyStore()

      authStore.user = { id: 1, email: 'test@example.com' }
      vi.spyOn(authStore, 'fetchCurrentUser').mockResolvedValue(true)
      vi.spyOn(stickyStore, 'fetchStickies').mockResolvedValue()
      vi.spyOn(stickyStore, 'deleteSticky').mockResolvedValue(true)

      stickyStore.stickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1, x: 0, y: 0, width: 1, height: 1 }
      ]

      const wrapper = mount(Home, {
        global: {
          plugins: [pinia, router]
        }
      })

      await flushPromises()

      // deleteSticky関数を直接呼び出す
      await wrapper.vm.deleteSticky(1)
      await flushPromises()

      // ダイアログが開いていることを確認
      expect(wrapper.vm.deleteDialogOpen).toBe(true)

      // ダイアログを閉じる（キャンセル）
      wrapper.vm.deleteDialogOpen = false
      wrapper.vm.deleteTargetId = null
      wrapper.vm.deleteTargetType = null
      await flushPromises()

      // 削除が実行されていないことを確認
      expect(stickyStore.deleteSticky).not.toHaveBeenCalled()
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

      // handleLogout関数を直接呼び出す
      await wrapper.vm.handleLogout()
      await flushPromises()

      expect(authStore.logout).toHaveBeenCalled()
      expect(pushSpy).toHaveBeenCalledWith('/login')
    })
  })
})
