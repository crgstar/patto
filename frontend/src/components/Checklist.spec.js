import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Checklist from './Checklist.vue'

describe('Checklist', () => {
  const mockChecklist = {
    id: 1,
    type: 'Checklist',
    title: 'テストチェックリスト',
    title_visible: true,
    checklist_items: [
      { id: 1, content: 'タスク1', checked: false, position: 0 },
      { id: 2, content: 'タスク2', checked: true, position: 1 },
      { id: 3, content: 'タスク3', checked: false, position: 2 }
    ]
  }

  describe('基本構造', () => {
    it('レンダリングできること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: mockChecklist,
          width: 2,
          height: 2
        }
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('propsを受け取ること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: mockChecklist,
          width: 2,
          height: 2
        }
      })

      expect(wrapper.props('checklist')).toEqual(mockChecklist)
      expect(wrapper.props('width')).toBe(2)
      expect(wrapper.props('height')).toBe(2)
    })

    it('削除イベントを発火すること', async () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: mockChecklist,
          width: 2,
          height: 2
        }
      })

      await wrapper.vm.handleDelete()

      expect(wrapper.emitted('delete')).toBeTruthy()
      expect(wrapper.emitted('delete')[0]).toEqual([1])
    })
  })

  describe('タイトル表示/非表示', () => {
    it('title_visibleがtrueでheight>1の場合、タイトルが表示されること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: { ...mockChecklist, title_visible: true },
          width: 2,
          height: 2
        }
      })

      expect(wrapper.vm.showTitle).toBe(true)
    })

    it('title_visibleがfalseの場合、タイトルが非表示になること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: { ...mockChecklist, title_visible: false },
          width: 2,
          height: 2
        }
      })

      expect(wrapper.vm.showTitle).toBe(false)
    })

    it('height<=1の場合、title_visibleがtrueでもタイトルが非表示になること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: { ...mockChecklist, title_visible: true },
          width: 2,
          height: 1
        }
      })

      expect(wrapper.vm.showTitle).toBe(false)
    })

    it('toggleTitleVisibleがupdate-title-visibleイベントを発火すること', async () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: { ...mockChecklist, title_visible: true },
          width: 2,
          height: 2
        }
      })

      await wrapper.vm.toggleTitleVisible()

      expect(wrapper.emitted('update-title-visible')).toBeTruthy()
      expect(wrapper.emitted('update-title-visible')[0]).toEqual([1, false])
    })

    it('finishEditingTitleがupdate-titleイベントを発火すること', async () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: { ...mockChecklist, title_visible: true },
          width: 2,
          height: 2
        }
      })

      wrapper.vm.editingTitle = true
      wrapper.vm.titleInputValue = '新しいタイトル'
      await wrapper.vm.$nextTick()

      await wrapper.vm.finishEditingTitle()

      expect(wrapper.emitted('update-title')).toBeTruthy()
      expect(wrapper.emitted('update-title')[0]).toEqual([1, '新しいタイトル'])
      expect(wrapper.vm.editingTitle).toBe(false)
    })
  })

  describe('チェックリスト機能', () => {
    it('完了数と合計数を正しく計算すること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: mockChecklist,
          width: 2,
          height: 2
        }
      })

      expect(wrapper.vm.completedCount).toBe(1)
      expect(wrapper.vm.totalCount).toBe(3)
    })

    it('完了率を正しく計算すること', () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: mockChecklist,
          width: 2,
          height: 2
        }
      })

      // 1/3 = 33.333... → 33%
      expect(wrapper.vm.completionPercentage).toBe(33)
    })

    it('add-itemイベントを発火すること', async () => {
      const wrapper = mount(Checklist, {
        props: {
          checklist: mockChecklist,
          width: 2,
          height: 2
        }
      })

      wrapper.vm.newItemContent = '新しいタスク'
      await wrapper.vm.handleAddItem()

      expect(wrapper.emitted('add-item')).toBeTruthy()
      expect(wrapper.emitted('add-item')[0]).toEqual(['新しいタスク'])
      expect(wrapper.vm.newItemContent).toBe('')
    })
  })
})
