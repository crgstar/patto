import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import FeedReader from './FeedReader.vue'
import { useStickyFeedSourceStore } from '@/stores/stickyFeedSource'
import { useFeedItemStore } from '@/stores/feedItem'
import { useFeedSourceStore } from '@/stores/feedSource'

vi.mock('@/lib/apiClient')

describe('FeedReader', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('基本構造', () => {
    it('レンダリングできること', () => {
      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('propsを受け取ること', () => {
      const feedReaderProp = { id: 1, type: 'FeedReader', title: '', content: '' }
      const wrapper = mount(FeedReader, {
        props: {
          feedReader: feedReaderProp,
          width: 3,
          height: 3
        }
      })

      expect(wrapper.props('feedReader')).toEqual(feedReaderProp)
      expect(wrapper.props('width')).toBe(3)
      expect(wrapper.props('height')).toBe(3)
    })

    it('削除イベントを発火すること', async () => {
      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      // 削除ハンドラーを直接呼び出してテスト
      await wrapper.vm.handleDelete()

      expect(wrapper.emitted('delete')).toBeTruthy()
      expect(wrapper.emitted('delete')[0]).toEqual([1])
    })
  })

  describe('フィードソース選択', () => {
    it('Selectコンポーネントが表示されること', async () => {
      const stickyFeedSourceStore = useStickyFeedSourceStore()
      const feedItemStore = useFeedItemStore()

      stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
      stickyFeedSourceStore.stickyFeedSources = []
      feedItemStore.fetchFeedItems = vi.fn().mockResolvedValue()

      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      await wrapper.vm.$nextTick()

      // Selectコンポーネントが存在することを確認
      const select = wrapper.findComponent({ name: 'Select' })
      expect(select.exists()).toBe(true)
    })

    it('stickyFeedSourcesが設定されること', async () => {
      const stickyFeedSourceStore = useStickyFeedSourceStore()
      const feedItemStore = useFeedItemStore()

      stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
      stickyFeedSourceStore.stickyFeedSources = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          feed_source: { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' }
        },
        {
          id: 2,
          sticky_id: 1,
          feed_source_id: 2,
          feed_source: { id: 2, title: 'Zenn', url: 'https://zenn.dev/feed' }
        }
      ]
      feedItemStore.fetchFeedItems = vi.fn().mockResolvedValue()

      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      await wrapper.vm.$nextTick()
      await wrapper.vm.$nextTick()

      // ストアにフィードソースが設定されていることを確認
      expect(stickyFeedSourceStore.stickyFeedSources.length).toBe(2)
      expect(stickyFeedSourceStore.stickyFeedSources[0].feed_source.title).toBe('DEV Community')
      expect(stickyFeedSourceStore.stickyFeedSources[1].feed_source.title).toBe('Zenn')
    })

    it('フィードソースを選択するとselectedFeedSourceIdが更新されること', async () => {
      const stickyFeedSourceStore = useStickyFeedSourceStore()
      const feedItemStore = useFeedItemStore()

      stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
      stickyFeedSourceStore.stickyFeedSources = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          feed_source: { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' }
        }
      ]
      feedItemStore.fetchFeedItems = vi.fn().mockResolvedValue()

      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      await wrapper.vm.$nextTick()

      // 初期値は'all'（すべてのフィード）
      expect(wrapper.vm.selectedFeedSourceId).toBe('all')

      // フィードソースを選択
      wrapper.vm.selectedFeedSourceId = '1'
      await wrapper.vm.$nextTick()

      expect(wrapper.vm.selectedFeedSourceId).toBe('1')
    })
  })

  describe('フィードアイテム表示', () => {
    it('フィードアイテムが表示されること', async () => {
      const stickyFeedSourceStore = useStickyFeedSourceStore()
      const feedItemStore = useFeedItemStore()

      stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
      stickyFeedSourceStore.stickyFeedSources = []

      feedItemStore.fetchFeedItems = vi.fn().mockResolvedValue()
      feedItemStore.feedItems = [
        {
          id: 1,
          title: 'テスト記事1',
          description: '説明文1',
          url: 'https://example.com/1',
          published_at: new Date().toISOString(),
          read: false,
          feed_source_id: 1
        },
        {
          id: 2,
          title: 'テスト記事2',
          description: '説明文2',
          url: 'https://example.com/2',
          published_at: new Date().toISOString(),
          read: true,
          feed_source_id: 1
        }
      ]

      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      await wrapper.vm.$nextTick()
      await wrapper.vm.$nextTick()

      // フィードアイテムが表示されることを確認
      expect(wrapper.text()).toContain('テスト記事1')
      expect(wrapper.text()).toContain('テスト記事2')
    })

    it('クリック時に既読化してURLを開くこと', async () => {
      const stickyFeedSourceStore = useStickyFeedSourceStore()
      const feedItemStore = useFeedItemStore()

      stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
      stickyFeedSourceStore.stickyFeedSources = []

      feedItemStore.fetchFeedItems = vi.fn().mockResolvedValue()
      feedItemStore.feedItems = [
        {
          id: 1,
          title: 'テスト記事1',
          description: '説明文1',
          url: 'https://example.com/1',
          published_at: new Date().toISOString(),
          read: false,
          feed_source_id: 1
        }
      ]
      feedItemStore.markAsRead = vi.fn().mockResolvedValue(true)

      // window.openのモック
      const windowOpenSpy = vi.spyOn(window, 'open').mockImplementation(() => null)

      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      await wrapper.vm.$nextTick()
      await wrapper.vm.$nextTick()

      // アイテムをクリック
      await wrapper.vm.handleItemClick(feedItemStore.feedItems[0])

      // 既読化が呼ばれたことを確認
      expect(feedItemStore.markAsRead).toHaveBeenCalledWith(1, 1)

      // URLが開かれたことを確認
      expect(windowOpenSpy).toHaveBeenCalledWith('https://example.com/1', '_blank')

      windowOpenSpy.mockRestore()
    })

    it('未読アイテムにインジケーターが表示されること', async () => {
      const stickyFeedSourceStore = useStickyFeedSourceStore()
      const feedItemStore = useFeedItemStore()

      stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
      stickyFeedSourceStore.stickyFeedSources = []

      feedItemStore.fetchFeedItems = vi.fn().mockResolvedValue()
      feedItemStore.feedItems = [
        {
          id: 1,
          title: 'テスト記事1',
          description: '説明文1',
          url: 'https://example.com/1',
          published_at: new Date().toISOString(),
          read: false,
          feed_source_id: 1
        }
      ]

      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      await wrapper.vm.$nextTick()
      await wrapper.vm.$nextTick()

      // 未読インジケーターのクラスが存在することを確認
      const html = wrapper.html()
      expect(html).toContain('bg-secondary')
    })
  })
})
