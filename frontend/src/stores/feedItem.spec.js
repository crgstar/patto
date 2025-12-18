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
