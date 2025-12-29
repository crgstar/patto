import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useFeedItemStore } from './feedItem'
import apiClient from '@/lib/apiClient'

vi.mock('@/lib/apiClient')

describe('useFeedItemStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('fetchFeedItems', () => {
    it('フィードアイテム一覧を取得できる', async () => {
      const store = useFeedItemStore()

      const mockFeedItems = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          title: 'Test Article 1',
          description: 'Description 1',
          url: 'https://example.com/1',
          published_at: '2025-12-17T00:00:00Z',
          read: false
        },
        {
          id: 2,
          sticky_id: 1,
          feed_source_id: 1,
          title: 'Test Article 2',
          description: 'Description 2',
          url: 'https://example.com/2',
          published_at: '2025-12-17T01:00:00Z',
          read: true
        }
      ]

      apiClient.get.mockResolvedValue({
        data: {
          feed_items: mockFeedItems,
          has_more: true
        }
      })

      await store.fetchFeedItems(1, { offset: 0, limit: 20 })

      expect(apiClient.get).toHaveBeenCalledWith('/stickies/1/feed_items', {
        params: { offset: 0, limit: 20 }
      })
      expect(store.feedItems).toEqual(mockFeedItems)
      expect(store.hasMore).toBe(true)
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('フィルターパラメータを指定してフィードアイテムを取得できる', async () => {
      const store = useFeedItemStore()

      const mockFeedItems = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          title: 'Unread Article',
          url: 'https://example.com/1',
          read: false
        }
      ]

      apiClient.get.mockResolvedValue({
        data: {
          feed_items: mockFeedItems,
          has_more: false
        }
      })

      await store.fetchFeedItems(1, { offset: 0, limit: 20, read: false })

      expect(apiClient.get).toHaveBeenCalledWith('/stickies/1/feed_items', {
        params: { offset: 0, limit: 20, read: false }
      })
      expect(store.feedItems).toEqual(mockFeedItems)
      expect(store.hasMore).toBe(false)
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedItemStore()

      apiClient.get.mockRejectedValue({
        response: { data: { error: 'Failed to fetch feed items' } }
      })

      await store.fetchFeedItems(1, { offset: 0, limit: 20 })

      expect(store.error).toBe('Failed to fetch feed items')
      expect(store.loading).toBe(false)
      expect(store.feedItems).toEqual([])
    })

    it('エラーレスポンスがない場合はデフォルトメッセージを使用する', async () => {
      const store = useFeedItemStore()

      apiClient.get.mockRejectedValue(new Error('Network error'))

      await store.fetchFeedItems(1, { offset: 0, limit: 20 })

      expect(store.error).toBe('フィードアイテムの取得に失敗しました')
      expect(store.loading).toBe(false)
    })

    it('offset > 0かつappend=trueの場合、既存データに追加すること', async () => {
      const store = useFeedItemStore()

      // 初回読み込み
      const firstResponse = {
        data: {
          feed_items: [
            { id: 1, title: '記事1', read: false },
            { id: 2, title: '記事2', read: false }
          ],
          has_more: true
        }
      }
      apiClient.get.mockResolvedValueOnce(firstResponse)
      await store.fetchFeedItems(1, { offset: 0, limit: 2 })

      expect(store.feedItems.length).toBe(2)

      // 2回目読み込み（追加）
      const secondResponse = {
        data: {
          feed_items: [
            { id: 3, title: '記事3', read: false },
            { id: 4, title: '記事4', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(secondResponse)
      await store.fetchFeedItems(1, { offset: 2, limit: 2, append: true })

      expect(store.feedItems.length).toBe(4)
      expect(store.feedItems[0].id).toBe(1)
      expect(store.feedItems[3].id).toBe(4)
      expect(store.hasMore).toBe(false)
    })

    it('append=falseの場合、既存データをクリアして上書きすること', async () => {
      const store = useFeedItemStore()

      // 初回読み込み
      const firstResponse = {
        data: {
          feed_items: [
            { id: 1, title: '記事1', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(firstResponse)
      await store.fetchFeedItems(1, { offset: 0, limit: 20 })

      // フィードソース変更（append=false）
      const secondResponse = {
        data: {
          feed_items: [
            { id: 10, title: '別フィード記事', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(secondResponse)
      await store.fetchFeedItems(1, { offset: 0, limit: 20, feed_source_id: 2, append: false })

      expect(store.feedItems.length).toBe(1)
      expect(store.feedItems[0].id).toBe(10)
    })

    it('offsetが0の場合、appendがtrueでも上書きすること', async () => {
      const store = useFeedItemStore()

      // 初回読み込み
      const firstResponse = {
        data: {
          feed_items: [
            { id: 1, title: '記事1', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(firstResponse)
      await store.fetchFeedItems(1, { offset: 0, limit: 20 })

      // offset=0、append=trueでも上書き
      const secondResponse = {
        data: {
          feed_items: [
            { id: 10, title: '新しい記事', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(secondResponse)
      await store.fetchFeedItems(1, { offset: 0, limit: 20, append: true })

      expect(store.feedItems.length).toBe(1)
      expect(store.feedItems[0].id).toBe(10)
    })

    it('appendパラメータがない場合はデフォルトで上書きすること', async () => {
      const store = useFeedItemStore()

      // 初回読み込み
      const firstResponse = {
        data: {
          feed_items: [
            { id: 1, title: '記事1', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(firstResponse)
      await store.fetchFeedItems(1, { offset: 0, limit: 20 })

      // appendパラメータなし
      const secondResponse = {
        data: {
          feed_items: [
            { id: 10, title: '新しい記事', read: false }
          ],
          has_more: false
        }
      }
      apiClient.get.mockResolvedValueOnce(secondResponse)
      await store.fetchFeedItems(1, { offset: 5, limit: 20 })

      expect(store.feedItems.length).toBe(1)
      expect(store.feedItems[0].id).toBe(10)
    })
  })

  describe('resetFeedItems', () => {
    it('feedItemsとhasMoreをリセットすること', () => {
      const store = useFeedItemStore()
      store.feedItems = [{ id: 1, title: '記事1' }]
      store.hasMore = false

      store.resetFeedItems()

      expect(store.feedItems).toEqual([])
      expect(store.hasMore).toBe(true)
    })
  })

  describe('markAsRead', () => {
    it('フィードアイテムを既読にできる', async () => {
      const store = useFeedItemStore()

      store.feedItems = [
        { id: 1, sticky_id: 1, title: 'Test', read: false },
        { id: 2, sticky_id: 1, title: 'Test 2', read: false }
      ]

      const updatedFeedItem = {
        id: 1,
        sticky_id: 1,
        title: 'Test',
        read: true
      }

      apiClient.post.mockResolvedValue({ data: { feed_item: updatedFeedItem } })

      const result = await store.markAsRead(1, 1)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/stickies/1/feed_items/1/mark_as_read')
      expect(store.feedItems[0].read).toBe(true)
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedItemStore()

      store.feedItems = [{ id: 1, sticky_id: 1, title: 'Test', read: false }]

      apiClient.post.mockRejectedValue({
        response: { data: { error: 'Not found' } }
      })

      const result = await store.markAsRead(1, 1)

      expect(result).toBe(false)
      expect(store.error).toBe('Not found')
      expect(store.loading).toBe(false)
    })
  })

  describe('markAsUnread', () => {
    it('フィードアイテムを未読にできる', async () => {
      const store = useFeedItemStore()

      store.feedItems = [
        { id: 1, sticky_id: 1, title: 'Test', read: true }
      ]

      const updatedFeedItem = {
        id: 1,
        sticky_id: 1,
        title: 'Test',
        read: false
      }

      apiClient.post.mockResolvedValue({ data: { feed_item: updatedFeedItem } })

      const result = await store.markAsUnread(1, 1)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/stickies/1/feed_items/1/mark_as_unread')
      expect(store.feedItems[0].read).toBe(false)
      expect(store.error).toBeNull()
    })
  })

  describe('markAllAsRead', () => {
    it('全てのフィードアイテムを既読にできる', async () => {
      const store = useFeedItemStore()

      store.feedItems = [
        { id: 1, sticky_id: 1, title: 'Test 1', read: false },
        { id: 2, sticky_id: 1, title: 'Test 2', read: false },
        { id: 3, sticky_id: 1, title: 'Test 3', read: true }
      ]

      apiClient.post.mockResolvedValue({})

      const result = await store.markAllAsRead(1)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/stickies/1/feed_items/mark_all_as_read')
      expect(store.feedItems.every(item => item.read)).toBe(true)
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedItemStore()

      apiClient.post.mockRejectedValue({
        response: { data: { error: 'Failed to mark all as read' } }
      })

      const result = await store.markAllAsRead(1)

      expect(result).toBe(false)
      expect(store.error).toBe('Failed to mark all as read')
    })
  })

  describe('refreshAll', () => {
    it('全てのフィードを更新できる', async () => {
      const store = useFeedItemStore()

      apiClient.post.mockResolvedValue({})

      const result = await store.refreshAll(1)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/stickies/1/refresh_all')
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedItemStore()

      apiClient.post.mockRejectedValue({
        response: { data: { error: 'Failed to refresh feeds' } }
      })

      const result = await store.refreshAll(1)

      expect(result).toBe(false)
      expect(store.error).toBe('Failed to refresh feeds')
      expect(store.loading).toBe(false)
    })
  })
})
