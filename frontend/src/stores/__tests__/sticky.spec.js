import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useStickyStore } from '../sticky'
import apiClient from '@/lib/apiClient'

vi.mock('@/lib/apiClient')

describe('useStickyStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('layout computed', () => {
    it('stickiesをgrid-layout-plus形式に変換する', () => {
      const store = useStickyStore()

      // テスト用のstickiesデータを設定
      store.stickies = [
        { id: 1, x: 0, y: 0, width: 2, height: 2, title: 'Sticky 1', content: 'Content 1' },
        { id: 2, x: 2, y: 0, width: 1, height: 1, title: 'Sticky 2', content: 'Content 2' },
        { id: 3, x: 0, y: 2, width: 3, height: 2, title: 'Sticky 3', content: 'Content 3' }
      ]

      const layout = store.layout

      expect(layout).toHaveLength(3)
      expect(layout[0]).toEqual({
        i: '1',
        x: 0,
        y: 0,
        w: 2,
        h: 2,
        sticky: store.stickies[0]
      })
      expect(layout[1]).toEqual({
        i: '2',
        x: 2,
        y: 0,
        w: 1,
        h: 1,
        sticky: store.stickies[1]
      })
      expect(layout[2]).toEqual({
        i: '3',
        x: 0,
        y: 2,
        w: 3,
        h: 2,
        sticky: store.stickies[2]
      })
    })

    it('座標がnullの場合はデフォルト値を使用する', () => {
      const store = useStickyStore()

      store.stickies = [
        { id: 1, x: null, y: null, width: null, height: null, title: 'Sticky 1' }
      ]

      const layout = store.layout

      expect(layout[0]).toEqual({
        i: '1',
        x: 0,
        y: 0,
        w: 1,
        h: 1,
        sticky: store.stickies[0]
      })
    })
  })

  describe('updateLayout', () => {
    it('レイアウト変更をサーバーに送信する', async () => {
      const store = useStickyStore()

      apiClient.patch.mockResolvedValue({ data: { message: 'Success' } })

      const newLayout = [
        { i: '1', x: 1, y: 1, w: 2, h: 2 },
        { i: '2', x: 3, y: 1, w: 1, h: 1 }
      ]

      await store.updateLayout(newLayout)

      expect(apiClient.patch).toHaveBeenCalledWith('/stickies/reorder', {
        stickies: [
          { id: 1, x: 1, y: 1, w: 2, h: 2 },
          { id: 2, x: 3, y: 1, w: 1, h: 1 }
        ]
      })
    })

    it('エラーが発生した場合はエラーメッセージを設定する', async () => {
      const store = useStickyStore()

      apiClient.patch.mockRejectedValue({
        response: { data: { error: 'Update failed' } }
      })

      const newLayout = [{ i: '1', x: 0, y: 0, w: 2, h: 2 }]

      const result = await store.updateLayout(newLayout)

      expect(result).toBe(false)
      expect(store.error).toBe('Update failed')
    })
  })

  describe('createSticky with coordinates', () => {
    it('座標を指定してStickyを作成する', async () => {
      const store = useStickyStore()

      const newSticky = {
        id: 1,
        type: 'PlainSticky',
        title: 'New Sticky',
        content: 'Content',
        x: 2,
        y: 3,
        width: 2,
        height: 2
      }

      apiClient.post.mockResolvedValue({ data: { sticky: newSticky } })

      const stickyData = {
        type: 'PlainSticky',
        title: 'New Sticky',
        content: 'Content',
        x: 2,
        y: 3,
        width: 2,
        height: 2
      }

      const result = await store.createSticky(stickyData)

      expect(result).toBe(true)
      expect(apiClient.post).toHaveBeenCalledWith('/stickies', {
        sticky: stickyData
      })
      expect(store.stickies).toContainEqual(newSticky)
    })

    it('座標を省略した場合はサーバー側でauto_position!が実行される', async () => {
      const store = useStickyStore()

      const newSticky = {
        id: 1,
        type: 'PlainSticky',
        title: 'New Sticky',
        content: 'Content',
        x: 0,
        y: 0,
        width: 1,
        height: 1
      }

      apiClient.post.mockResolvedValue({ data: { sticky: newSticky } })

      const stickyData = {
        type: 'PlainSticky',
        title: 'New Sticky',
        content: 'Content'
      }

      const result = await store.createSticky(stickyData)

      expect(result).toBe(true)
      expect(store.stickies[0].x).toBe(0)
      expect(store.stickies[0].y).toBe(0)
    })
  })
})
