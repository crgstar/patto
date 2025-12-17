import { defineStore } from 'pinia'
import { ref } from 'vue'
import apiClient from '@/lib/apiClient'

export const useFeedSourceStore = defineStore('feedSource', () => {
  const feedSources = ref([])
  const loading = ref(false)
  const error = ref(null)

  // フィードソース一覧を取得
  const fetchFeedSources = async () => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.get('/feed_sources')
      feedSources.value = response.data.feed_sources
    } catch (err) {
      error.value = err.response?.data?.error || 'フィード一覧の取得に失敗しました'
    } finally {
      loading.value = false
    }
  }

  // フィードソースを作成
  const createFeedSource = async (feedSourceData) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post('/feed_sources', {
        feed_source: feedSourceData
      })

      feedSources.value.push(response.data.feed_source)
      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'フィードの作成に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // フィードソースを更新
  const updateFeedSource = async (id, feedSourceData) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.patch(`/feed_sources/${id}`, {
        feed_source: feedSourceData
      })

      const index = feedSources.value.findIndex(fs => fs.id === id)
      if (index !== -1) {
        feedSources.value[index] = response.data.feed_source
      }

      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'フィードの更新に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // フィードソースを削除（論理削除）
  const deleteFeedSource = async (id) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.delete(`/feed_sources/${id}`)

      feedSources.value = feedSources.value.filter(fs => fs.id !== id)
      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'フィードの削除に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    feedSources,
    loading,
    error,
    fetchFeedSources,
    createFeedSource,
    updateFeedSource,
    deleteFeedSource
  }
})
