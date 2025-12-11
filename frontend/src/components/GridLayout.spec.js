import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import GridLayout from './GridLayout.vue'

describe('GridLayout', () => {
  const createMockLayout = () => [
    {
      i: '1',
      x: 0,
      y: 0,
      w: 2,
      h: 2,
      sticky: {
        id: 1,
        type: 'Calendar',
        title: '',
        content: '',
        width: 2,
        height: 2
      }
    },
    {
      i: '2',
      x: 2,
      y: 0,
      w: 1,
      h: 1,
      sticky: {
        id: 2,
        type: 'Sticky',
        title: 'テスト',
        content: 'テスト内容',
        width: 1,
        height: 1
      }
    }
  ]

  it('レンダリングできること', () => {
    const wrapper = mount(GridLayout, {
      props: {
        layout: createMockLayout()
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('カレンダーをリサイズすると正方形に強制されること（幅を大きくした場合）', async () => {
    const layout = createMockLayout()
    const updateLayoutSpy = vi.fn()

    const wrapper = mount(GridLayout, {
      props: {
        layout,
        'onUpdate:layout': updateLayoutSpy
      }
    })

    // GridItemのresizeイベントをシミュレート
    // カレンダー（i='1'）を幅3、高さ2にリサイズ
    await wrapper.vm.handleResize('1', 2, 3)

    // update:layoutイベントが発火されたことを確認
    expect(updateLayoutSpy).toHaveBeenCalled()

    // 正方形（3x3）に強制されていることを確認
    const updatedLayout = updateLayoutSpy.mock.calls[0][0]
    const calendarItem = updatedLayout.find(item => item.i === '1')
    expect(calendarItem.w).toBe(3)
    expect(calendarItem.h).toBe(3)
  })

  it('カレンダーをリサイズすると正方形に強制されること（高さを大きくした場合）', async () => {
    const layout = createMockLayout()
    const updateLayoutSpy = vi.fn()

    const wrapper = mount(GridLayout, {
      props: {
        layout,
        'onUpdate:layout': updateLayoutSpy
      }
    })

    // カレンダー（i='1'）を幅2、高さ4にリサイズ
    await wrapper.vm.handleResize('1', 4, 2)

    // update:layoutイベントが発火されたことを確認
    expect(updateLayoutSpy).toHaveBeenCalled()

    // 正方形（3x3）に強制されていることを確認（カレンダーは2または3のみ）
    const updatedLayout = updateLayoutSpy.mock.calls[0][0]
    const calendarItem = updatedLayout.find(item => item.i === '1')
    expect(calendarItem.w).toBe(3)
    expect(calendarItem.h).toBe(3)
  })

  it('通常の付箋のリサイズは正方形に強制されないこと', async () => {
    const layout = createMockLayout()
    const updateLayoutSpy = vi.fn()

    const wrapper = mount(GridLayout, {
      props: {
        layout,
        'onUpdate:layout': updateLayoutSpy
      }
    })

    // 通常の付箋（i='2'）を幅3、高さ2にリサイズ
    await wrapper.vm.handleResize('2', 2, 3)

    // update:layoutイベントが発火されないことを確認
    expect(updateLayoutSpy).not.toHaveBeenCalled()
  })

  it('カレンダーがすでに正方形の場合は更新が発生しないこと', async () => {
    const layout = createMockLayout()
    const updateLayoutSpy = vi.fn()

    const wrapper = mount(GridLayout, {
      props: {
        layout,
        'onUpdate:layout': updateLayoutSpy
      }
    })

    // カレンダー（i='1'）をすでに正方形（2x2）にリサイズ
    await wrapper.vm.handleResize('1', 2, 2)

    // update:layoutイベントが発火されないことを確認（すでに正方形なので）
    expect(updateLayoutSpy).not.toHaveBeenCalled()
  })

  it('layout-updatedイベントが正しく伝播されること', () => {
    const layout = createMockLayout()
    const layoutUpdatedSpy = vi.fn()

    const wrapper = mount(GridLayout, {
      props: {
        layout,
        'onLayout-updated': layoutUpdatedSpy
      }
    })

    const newLayout = [...layout]
    wrapper.vm.handleLayoutUpdated(newLayout)

    expect(layoutUpdatedSpy).toHaveBeenCalledWith(newLayout)
  })

  it('layout-updated時にカレンダーが正方形に強制されること', () => {
    const layout = createMockLayout()
    const updateLayoutSpy = vi.fn()
    const layoutUpdatedSpy = vi.fn()

    const wrapper = mount(GridLayout, {
      props: {
        layout,
        'onUpdate:layout': updateLayoutSpy,
        'onLayout-updated': layoutUpdatedSpy
      }
    })

    // grid-layout-plusが内部的に非正方形のレイアウトを返すケースをシミュレート
    const nonSquareLayout = [
      {
        i: '1',
        x: 0,
        y: 0,
        w: 3, // 幅3
        h: 2, // 高さ2（非正方形）
        sticky: {
          id: 1,
          type: 'Calendar',
          title: '',
          content: '',
          width: 2,
          height: 2
        }
      }
    ]

    wrapper.vm.handleLayoutUpdated(nonSquareLayout)

    // update:layoutとlayout-updatedの両方が呼ばれていることを確認
    expect(updateLayoutSpy).toHaveBeenCalled()
    expect(layoutUpdatedSpy).toHaveBeenCalled()

    // 正方形（3x3）に補正されていることを確認
    const correctedLayout = updateLayoutSpy.mock.calls[0][0]
    const calendarItem = correctedLayout.find(item => item.i === '1')
    expect(calendarItem.w).toBe(3)
    expect(calendarItem.h).toBe(3)
  })
})
