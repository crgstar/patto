import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useStickyStore } from './sticky'
import axios from 'axios'

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

describe('Sticky Store', () => {
  let store

  beforeEach(() => {
    setActivePinia(createPinia())
    store = useStickyStore()
    vi.clearAllMocks()
  })

  describe('初期状態', () => {
    it('stickiesが空配列であること', () => {
      expect(store.stickies).toEqual([])
    })

    it('loadingがfalseであること', () => {
      expect(store.loading).toBe(false)
    })

    it('errorがnullであること', () => {
      expect(store.error).toBeNull()
    })
  })

  describe('fetchStickies', () => {
    it('Sticky一覧を取得できること', async () => {
      const mockStickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 },
        { id: 2, type: 'Sticky', title: 'Test 2', content: 'Content 2', position: 2 }
      ]

      axios.get.mockResolvedValue({ data: { stickies: mockStickies } })

      await store.fetchStickies()

      expect(axios.get).toHaveBeenCalled()
      expect(store.stickies).toEqual(mockStickies)
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('エラー時にerrorが設定されること', async () => {
      axios.get.mockRejectedValue({
        response: { data: { error: 'Failed to fetch' } }
      })

      await store.fetchStickies()

      expect(store.error).toBe('Failed to fetch')
      expect(store.stickies).toEqual([])
    })
  })

  describe('createSticky', () => {
    it('Stickyを作成できること', async () => {
      const newSticky = { id: 1, type: 'Sticky', title: 'New', content: 'Content', position: 1 }
      axios.post.mockResolvedValue({ data: { sticky: newSticky } })

      const result = await store.createSticky({
        type: 'Sticky',
        title: 'New',
        content: 'Content',
        position: 1
      })

      expect(result).toBe(true)
      expect(axios.post).toHaveBeenCalled()
      expect(store.stickies).toContainEqual(newSticky)
    })

    it('作成失敗時にfalseを返すこと', async () => {
      axios.post.mockRejectedValue({
        response: { data: { errors: ['Type is required'] } }
      })

      const result = await store.createSticky({ title: 'New' })

      expect(result).toBe(false)
      expect(store.error).toBe('Type is required')
    })
  })

  describe('updateSticky', () => {
    beforeEach(async () => {
      const mockStickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 }
      ]
      axios.get.mockResolvedValue({ data: { stickies: mockStickies } })
      await store.fetchStickies()
    })

    it('Stickyを更新できること', async () => {
      const updatedSticky = { id: 1, type: 'Sticky', title: 'Updated', content: 'Updated content', position: 1 }
      axios.patch.mockResolvedValue({ data: { sticky: updatedSticky } })

      const result = await store.updateSticky(1, { title: 'Updated', content: 'Updated content' })

      expect(result).toBe(true)
      expect(axios.patch).toHaveBeenCalled()
      expect(store.stickies[0].title).toBe('Updated')
    })

    it('更新失敗時にfalseを返すこと', async () => {
      axios.patch.mockRejectedValue({
        response: { data: { errors: ['Update failed'] } }
      })

      const result = await store.updateSticky(1, { title: 'Updated' })

      expect(result).toBe(false)
      expect(store.error).toBe('Update failed')
    })
  })

  describe('deleteSticky', () => {
    beforeEach(async () => {
      const mockStickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 },
        { id: 2, type: 'Sticky', title: 'Test 2', content: 'Content 2', position: 2 }
      ]
      axios.get.mockResolvedValue({ data: { stickies: mockStickies } })
      await store.fetchStickies()
    })

    it('Stickyを削除できること', async () => {
      axios.delete.mockResolvedValue({})

      const result = await store.deleteSticky(1)

      expect(result).toBe(true)
      expect(axios.delete).toHaveBeenCalled()
      expect(store.stickies).toHaveLength(1)
      expect(store.stickies[0].id).toBe(2)
    })

    it('削除失敗時にfalseを返すこと', async () => {
      axios.delete.mockRejectedValue({
        response: { data: { error: 'Delete failed' } }
      })

      const result = await store.deleteSticky(1)

      expect(result).toBe(false)
      expect(store.error).toBe('Delete failed')
    })
  })

  describe('reorderStickies', () => {
    beforeEach(async () => {
      const mockStickies = [
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 1 },
        { id: 2, type: 'Sticky', title: 'Test 2', content: 'Content 2', position: 2 }
      ]
      axios.get.mockResolvedValue({ data: { stickies: mockStickies } })
      await store.fetchStickies()
    })

    it('Stickyを並び替えできること', async () => {
      axios.patch.mockResolvedValue({ data: { message: 'Reordered' } })

      const reorderedStickies = [
        { id: 2, type: 'Sticky', title: 'Test 2', content: 'Content 2', position: 1 },
        { id: 1, type: 'Sticky', title: 'Test 1', content: 'Content 1', position: 2 }
      ]

      const result = await store.reorderStickies(reorderedStickies)

      expect(result).toBe(true)
      expect(axios.patch).toHaveBeenCalled()
      expect(store.stickies).toEqual(reorderedStickies)
    })

    it('並び替え失敗時にfalseを返すこと', async () => {
      axios.patch.mockRejectedValue({
        response: { data: { error: 'Reorder failed' } }
      })

      const result = await store.reorderStickies([])

      expect(result).toBe(false)
      expect(store.error).toBe('Reorder failed')
    })
  })
})
