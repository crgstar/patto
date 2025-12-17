import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useFeedSourceStore } from '../feedSource'
import apiClient from '@/lib/apiClient'

vi.mock('@/lib/apiClient')

describe('useFeedSourceStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('fetchFeedSources', () => {
    it('フィードソース一覧を取得できる', async () => {
      const store = useFeedSourceStore()

      const mockFeedSources = [
        {
          id: 1,
          url: 'https://dev.to/feed',
          title: 'DEV Community',
          description: 'Dev blog',
          user_id: 1,
          created_at: '2025-12-17T00:00:00Z',
          updated_at: '2025-12-17T00:00:00Z'
        },
        {
          id: 2,
          url: 'https://zenn.dev/feed',
          title: 'Zenn',
          description: 'Zenn blog',
          user_id: 1,
          created_at: '2025-12-17T01:00:00Z',
          updated_at: '2025-12-17T01:00:00Z'
        }
      ]

      apiClient.get.mockResolvedValue({ data: { feed_sources: mockFeedSources } })

      await store.fetchFeedSources()

      expect(apiClient.get).toHaveBeenCalledWith('/feed_sources')
      expect(store.feedSources).toEqual(mockFeedSources)
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedSourceStore()

      apiClient.get.mockRejectedValue({
        response: { data: { error: 'Failed to fetch feed sources' } }
      })

      await store.fetchFeedSources()

      expect(store.error).toBe('Failed to fetch feed sources')
      expect(store.loading).toBe(false)
      expect(store.feedSources).toEqual([])
    })

    it('エラーレスポンスがない場合はデフォルトメッセージを使用する', async () => {
      const store = useFeedSourceStore()

      apiClient.get.mockRejectedValue(new Error('Network error'))

      await store.fetchFeedSources()

      expect(store.error).toBe('フィード一覧の取得に失敗しました')
      expect(store.loading).toBe(false)
    })
  })

  describe('createFeedSource', () => {
    it('新しいフィードソースを作成できる', async () => {
      const store = useFeedSourceStore()

      const newFeedSource = {
        id: 1,
        url: 'https://dev.to/feed',
        title: 'DEV Community',
        description: 'Dev blog',
        user_id: 1,
        created_at: '2025-12-17T00:00:00Z',
        updated_at: '2025-12-17T00:00:00Z'
      }

      apiClient.post.mockResolvedValue({ data: { feed_source: newFeedSource } })

      const feedSourceData = {
        url: 'https://dev.to/feed',
        title: 'DEV Community',
        description: 'Dev blog'
      }

      const result = await store.createFeedSource(feedSourceData)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/feed_sources', {
        feed_source: feedSourceData
      })
      expect(store.feedSources).toContainEqual(newFeedSource)
      expect(store.error).toBeNull()
    })

    it('バリデーションエラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedSourceStore()

      apiClient.post.mockRejectedValue({
        response: { data: { errors: ['Url can\'t be blank'] } }
      })

      const feedSourceData = {
        url: '',
        title: 'Test',
        description: 'Test'
      }

      const result = await store.createFeedSource(feedSourceData)

      expect(result).toBe(false)
      expect(store.error).toBe('Url can\'t be blank')
      expect(store.loading).toBe(false)
    })

    it('エラーレスポンスがない場合はデフォルトメッセージを使用する', async () => {
      const store = useFeedSourceStore()

      apiClient.post.mockRejectedValue(new Error('Network error'))

      const feedSourceData = {
        url: 'https://dev.to/feed',
        title: 'DEV',
        description: 'Test'
      }

      const result = await store.createFeedSource(feedSourceData)

      expect(result).toBe(false)
      expect(store.error).toBe('フィードの作成に失敗しました')
    })
  })

  describe('updateFeedSource', () => {
    it('既存のフィードソースを更新できる', async () => {
      const store = useFeedSourceStore()

      const existingFeedSource = {
        id: 1,
        url: 'https://dev.to/feed',
        title: 'DEV Community',
        description: 'Dev blog',
        user_id: 1,
        created_at: '2025-12-17T00:00:00Z',
        updated_at: '2025-12-17T00:00:00Z'
      }

      store.feedSources = [existingFeedSource]

      const updatedFeedSource = {
        ...existingFeedSource,
        title: 'DEV Community Updated',
        description: 'Updated description',
        updated_at: '2025-12-17T02:00:00Z'
      }

      apiClient.patch.mockResolvedValue({ data: { feed_source: updatedFeedSource } })

      const updateData = {
        title: 'DEV Community Updated',
        description: 'Updated description'
      }

      const result = await store.updateFeedSource(1, updateData)

      expect(result).toBe(true)
      expect(apiClient.patch).toHaveBeenCalledWith('/feed_sources/1', {
        feed_source: updateData
      })
      expect(store.feedSources[0]).toEqual(updatedFeedSource)
      expect(store.error).toBeNull()
    })

    it('存在しないIDの場合でもエラーなく処理される', async () => {
      const store = useFeedSourceStore()

      store.feedSources = [{ id: 1, url: 'https://dev.to/feed', title: 'DEV' }]

      const updatedFeedSource = {
        id: 999,
        url: 'https://test.com/feed',
        title: 'Test',
        description: 'Test'
      }

      apiClient.patch.mockResolvedValue({ data: { feed_source: updatedFeedSource } })

      const result = await store.updateFeedSource(999, { title: 'Test' })

      expect(result).toBe(true)
      // 存在しないIDなので配列は変わらない
      expect(store.feedSources).toHaveLength(1)
      expect(store.feedSources[0].id).toBe(1)
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedSourceStore()

      apiClient.patch.mockRejectedValue({
        response: { data: { errors: ['Url has already been taken'] } }
      })

      const result = await store.updateFeedSource(1, { url: 'https://duplicate.com/feed' })

      expect(result).toBe(false)
      expect(store.error).toBe('Url has already been taken')
      expect(store.loading).toBe(false)
    })
  })

  describe('deleteFeedSource', () => {
    it('フィードソースを削除できる', async () => {
      const store = useFeedSourceStore()

      store.feedSources = [
        { id: 1, url: 'https://dev.to/feed', title: 'DEV' },
        { id: 2, url: 'https://zenn.dev/feed', title: 'Zenn' }
      ]

      apiClient.delete.mockResolvedValue({})

      const result = await store.deleteFeedSource(1)

      expect(result).toBe(true)
      expect(apiClient.delete).toHaveBeenCalledWith('/feed_sources/1')
      expect(store.feedSources).toHaveLength(1)
      expect(store.feedSources[0].id).toBe(2)
      expect(store.error).toBeNull()
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useFeedSourceStore()

      store.feedSources = [{ id: 1, url: 'https://dev.to/feed', title: 'DEV' }]

      apiClient.delete.mockRejectedValue({
        response: { data: { error: 'Not found' } }
      })

      const result = await store.deleteFeedSource(1)

      expect(result).toBe(false)
      expect(store.error).toBe('Not found')
      expect(store.loading).toBe(false)
      // 削除失敗なので配列は変わらない
      expect(store.feedSources).toHaveLength(1)
    })
  })
})
