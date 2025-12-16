import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import apiClient from '@/lib/apiClient'

export const useStickyStore = defineStore('sticky', () => {
  const stickies = ref([])
  const loading = ref(false)
  const error = ref(null)

  // stickiesをgrid-layout-plus形式に変換
  const layout = computed(() => {
    return stickies.value.map(sticky => ({
      i: String(sticky.id),
      x: sticky.x ?? 0,
      y: sticky.y ?? 0,
      w: sticky.width ?? 1,
      h: sticky.height ?? 1,
      sticky: sticky,
    }))
  })

  // Sticky一覧を取得
  const fetchStickies = async () => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.get('/stickies')
      stickies.value = response.data.stickies
    } catch (err) {
      error.value = err.response?.data?.error || 'Sticky一覧の取得に失敗しました'
    } finally {
      loading.value = false
    }
  }

  // Stickyを作成
  const createSticky = async (stickyData) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post('/stickies', {
        sticky: stickyData
      })

      stickies.value.push(response.data.sticky)
      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'Stickyの作成に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Stickyを更新
  const updateSticky = async (id, stickyData) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.patch(`/stickies/${id}`, {
        sticky: stickyData
      })

      const index = stickies.value.findIndex(s => s.id === id)
      if (index !== -1) {
        stickies.value[index] = response.data.sticky
      }

      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'Stickyの更新に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Stickyを削除（論理削除）
  const deleteSticky = async (id) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.delete(`/stickies/${id}`)

      stickies.value = stickies.value.filter(s => s.id !== id)
      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'Stickyの削除に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // Stickyを並び替え
  const reorderStickies = async (reorderedStickies) => {
    loading.value = true
    error.value = null

    try {
      // positionを更新
      const updates = reorderedStickies.map((sticky, index) => ({
        id: sticky.id,
        position: index + 1
      }))

      await apiClient.patch('/stickies/reorder', {
        stickies: updates
      })

      // ローカルステートを更新
      stickies.value = reorderedStickies.map((sticky, index) => ({
        ...sticky,
        position: index + 1
      }))

      return true
    } catch (err) {
      error.value = err.response?.data?.error || '並び替えに失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // レイアウト（座標）を更新
  const updateLayout = async (newLayout) => {
    loading.value = true
    error.value = null

    try {
      // grid-layout-plus形式からAPIリクエスト形式に変換
      const updates = newLayout.map(item => ({
        id: parseInt(item.i),
        x: item.x,
        y: item.y,
        w: item.w,
        h: item.h
      }))

      await apiClient.patch('/stickies/reorder', {
        stickies: updates
      })

      // ローカルステートを更新
      newLayout.forEach(item => {
        const sticky = stickies.value.find(s => s.id === parseInt(item.i))
        if (sticky) {
          sticky.x = item.x
          sticky.y = item.y
          sticky.width = item.w
          sticky.height = item.h
        }
      })

      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'レイアウトの更新に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // ChecklistItemを作成
  const createChecklistItem = async (checklistId, content) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.post(`/stickies/${checklistId}/checklist_items`, {
        checklist_item: {
          content,
          position: 0
        }
      })

      // ローカルステートを更新（stickies配列全体を再作成）
      stickies.value = stickies.value.map(s => {
        if (s.id === checklistId) {
          const items = s.checklist_items || []
          return {
            ...s,
            checklist_items: [...items, response.data.checklist_item]
          }
        }
        return s
      })

      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'アイテムの作成に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // ChecklistItemを更新
  const updateChecklistItem = async (checklistId, itemId, updates) => {
    loading.value = true
    error.value = null

    try {
      const response = await apiClient.patch(`/stickies/${checklistId}/checklist_items/${itemId}`, {
        checklist_item: updates
      })
      console.log('[Store] updateChecklistItem response:', response.data);

      // ローカルステートを更新（stickies配列全体を再作成）
      stickies.value = stickies.value.map(s => {
        if (s.id === checklistId && s.checklist_items) {
          return {
            ...s,
            checklist_items: s.checklist_items.map(item =>
              item.id === itemId ? response.data.checklist_item : item
            )
          }
        }
        return s
      })

      return true
    } catch (err) {
      error.value = err.response?.data?.errors?.[0] || 'アイテムの更新に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  // ChecklistItemを削除（論理削除）
  const deleteChecklistItem = async (checklistId, itemId) => {
    loading.value = true
    error.value = null

    try {
      await apiClient.delete(`/stickies/${checklistId}/checklist_items/${itemId}`)

      // ローカルステートを更新（stickies配列全体を再作成）
      stickies.value = stickies.value.map(s => {
        if (s.id === checklistId && s.checklist_items) {
          return {
            ...s,
            checklist_items: s.checklist_items.filter(item => item.id !== itemId)
          }
        }
        return s
      })

      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'アイテムの削除に失敗しました'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    stickies,
    loading,
    error,
    layout,
    fetchStickies,
    createSticky,
    updateSticky,
    deleteSticky,
    reorderStickies,
    updateLayout,
    createChecklistItem,
    updateChecklistItem,
    deleteChecklistItem
  }
})
