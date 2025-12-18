import { defineStore } from 'pinia'
import { ref } from 'vue'
import apiClient from '@/lib/apiClient'

export const useFeedItemStore = defineStore('feedItem', () => {
  const feedItems = ref([])
  const loading = ref(false)
  const error = ref(null)
  const hasMore = ref(true)

  // フィードアイテム一覧を取得（ページネーション対応）
  const fetchFeedItems = async (stickyId, params = {}) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.get(`/stickies/${stickyId}/feed_items`, {
        params: {
          offset: params.offset || 0,
          limit: params.limit || 20,
          ...(params.read !== undefined && { read: params.read }),
          ...(params.feed_source_id && { feed_source_id: params.feed_source_id })
        }
      })

      feedItems.value = response.data.feed_items
      hasMore.value = response.data.has_more !== undefined ? response.data.has_more : false
    } catch (err) {
      error.value = err.response?.data?.error || 'フィードアイテムの取得に失敗しました'
    } finally {
      loading.value = false
    }
  }

  // フィードアイテムを既読にする
  const markAsRead = async (stickyId, feedItemId) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post(`/stickies/${stickyId}/feed_items/${feedItemId}/mark_as_read`)

      const index = feedItems.value.findIndex(item => item.id === feedItemId)
      if (index !== -1) {
        feedItems.value[index] = response.data.feed_item
      }

      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'フィードの既読化に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // フィードアイテムを未読にする
  const markAsUnread = async (stickyId, feedItemId) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post(`/stickies/${stickyId}/feed_items/${feedItemId}/mark_as_unread`)

      const index = feedItems.value.findIndex(item => item.id === feedItemId)
      if (index !== -1) {
        feedItems.value[index] = response.data.feed_item
      }

      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'フィードの未読化に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // 全てのフィードアイテムを既読にする
  const markAllAsRead = async (stickyId) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.post(`/stickies/${stickyId}/feed_items/mark_all_as_read`)

      // ローカルの全てのアイテムを既読にする
      feedItems.value.forEach(item => {
        item.read = true
      })

      return true
    } catch (err) {
      error.value = err.response?.data?.error || '一括既読化に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // 全てのフィードを更新（新しいフィードを取得）
  const refreshAll = async (stickyId) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.post(`/stickies/${stickyId}/refresh_all`)
      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'フィードの更新に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    feedItems,
    loading,
    error,
    hasMore,
    fetchFeedItems,
    markAsRead,
    markAsUnread,
    markAllAsRead,
    refreshAll
  }
})
