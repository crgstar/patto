import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useStickyFeedSourceStore } from '../stickyFeedSource'
import apiClient from '@/lib/apiClient'

vi.mock('@/lib/apiClient')

describe('useStickyFeedSourceStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('fetchStickyFeedSources', () => {
    it('Sticky用フィードソース一覧を取得できる', async () => {
      const store = useStickyFeedSourceStore()

      const mockStickyFeedSources = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          feed_source: {
            id: 1,
            url: 'https://dev.to/feed',
            title: 'DEV Community',
            description: 'Dev blog'
          },
          created_at: '2025-12-17T00:00:00Z',
          updated_at: '2025-12-17T00:00:00Z'
        },
        {
          id: 2,
          sticky_id: 1,
          feed_source_id: 2,
          feed_source: {
            id: 2,
            url: 'https://zenn.dev/feed',
            title: 'Zenn',
            description: 'Zenn blog'
          },
          created_at: '2025-12-17T01:00:00Z',
          updated_at: '2025-12-17T01:00:00Z'
        }
      ]

      apiClient.get.mockResolvedValue({ data: { sticky_feed_sources: mockStickyFeedSources } })

      await store.fetchStickyFeedSources(1)

      expect(apiClient.get).toHaveBeenCalledWith('/stickies/1/sticky_feed_sources')
      expect(store.stickyFeedSources).toEqual(mockStickyFeedSources)
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useStickyFeedSourceStore()

      apiClient.get.mockRejectedValue({
        response: { data: { error: 'Failed to fetch sticky feed sources' } }
      })

      await store.fetchStickyFeedSources(1)

      expect(store.error).toBe('Failed to fetch sticky feed sources')
      expect(store.loading).toBe(false)
      expect(store.stickyFeedSources).toEqual([])
    })

    it('エラーレスポンスがない場合はデフォルトメッセージを使用する', async () => {
      const store = useStickyFeedSourceStore()

      apiClient.get.mockRejectedValue(new Error('Network error'))

      await store.fetchStickyFeedSources(1)

      expect(store.error).toBe('Sticky用フィード一覧の取得に失敗しました')
      expect(store.loading).toBe(false)
    })
  })

  describe('createStickyFeedSource', () => {
    it('新しいSticky用フィードソースを作成できる', async () => {
      const store = useStickyFeedSourceStore()

      const newStickyFeedSource = {
        id: 1,
        sticky_id: 1,
        feed_source_id: 1,
        feed_source: {
          id: 1,
          url: 'https://dev.to/feed',
          title: 'DEV Community',
          description: 'Dev blog'
        },
        created_at: '2025-12-17T00:00:00Z',
        updated_at: '2025-12-17T00:00:00Z'
      }

      apiClient.post.mockResolvedValue({ data: { sticky_feed_source: newStickyFeedSource } })

      const result = await store.createStickyFeedSource(1, 1)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/stickies/1/sticky_feed_sources', {
        sticky_feed_source: { feed_source_id: 1 }
      })
      expect(store.stickyFeedSources).toContainEqual(newStickyFeedSource)
      expect(store.error).toBeNull()
    })

    it('バリデーションエラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useStickyFeedSourceStore()

      apiClient.post.mockRejectedValue({
        response: { data: { errors: ['Feed source must exist'] } }
      })

      const result = await store.createStickyFeedSource(1, 999)

      expect(result).toBe(false)
      expect(store.error).toBe('Feed source must exist')
      expect(store.loading).toBe(false)
    })

    it('エラーレスポンスがない場合はデフォルトメッセージを使用する', async () => {
      const store = useStickyFeedSourceStore()

      apiClient.post.mockRejectedValue(new Error('Network error'))

      const result = await store.createStickyFeedSource(1, 1)

      expect(result).toBe(false)
      expect(store.error).toBe('Sticky用フィードの追加に失敗しました')
    })
  })

  describe('deleteStickyFeedSource', () => {
    it('Sticky用フィードソースを削除できる', async () => {
      const store = useStickyFeedSourceStore()

      store.stickyFeedSources = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          feed_source: { id: 1, title: 'DEV' }
        },
        {
          id: 2,
          sticky_id: 1,
          feed_source_id: 2,
          feed_source: { id: 2, title: 'Zenn' }
        }
      ]

      apiClient.delete.mockResolvedValue({})

      const result = await store.deleteStickyFeedSource(1, 1)

      expect(result).toBe(true)
      expect(apiClient.delete).toHaveBeenCalledWith('/stickies/1/sticky_feed_sources/1')
      expect(store.stickyFeedSources).toHaveLength(1)
      expect(store.stickyFeedSources[0].id).toBe(2)
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useStickyFeedSourceStore()

      store.stickyFeedSources = [
        {
          id: 1,
          sticky_id: 1,
          feed_source_id: 1,
          feed_source: { id: 1, title: 'DEV' }
        }
      ]

      apiClient.delete.mockRejectedValue({
        response: { data: { error: 'Not found' } }
      })

      const result = await store.deleteStickyFeedSource(1, 1)

      expect(result).toBe(false)
      expect(store.error).toBe('Not found')
      expect(store.loading).toBe(false)
      // 削除失敗なので配列は変わらない
      expect(store.stickyFeedSources).toHaveLength(1)
    })
  })
})
