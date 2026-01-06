import { describe, it, expect, vi, beforeAll } from 'vitest'
import { mount } from '@vue/test-utils'
import Calendar from './Calendar.vue'

// ResizeObserverのモック
beforeAll(() => {
  global.ResizeObserver = class ResizeObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
  }
})

describe('Calendar', () => {
  const mockSticky = {
    id: 1,
    type: 'Calendar',
    title: '',
    content: '',
    width: 2,
    height: 2
  }

  it('レンダリングできること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('VCalendarコンポーネントが存在すること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // VCalendarのコンポーネントまたはクラスが存在することを確認
    const calendarElement = wrapper.find('[data-testid="vcalendar"]')
    expect(calendarElement.exists()).toBe(true)
  })

  it('削除ボタンをクリックするとdeleteイベントを発火すること', async () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // handleDeleteメソッドを直接呼び出してテスト
    wrapper.vm.handleDelete()
    await wrapper.vm.$nextTick()

    expect(wrapper.emitted('delete')).toBeTruthy()
    expect(wrapper.emitted('delete')[0]).toEqual([mockSticky.id])
  })

  it('小サイズ（1x1）で適切なスケールが適用されること', () => {
    const smallSticky = { ...mockSticky, width: 1, height: 1 }
    const wrapper = mount(Calendar, {
      props: {
        sticky: smallSticky
      }
    })

    // getScaleが0.4になっていることを確認
    expect(wrapper.vm.getScale).toBe(0.4)
  })

  it('中サイズ（2x2）で適切なスケールが適用されること', () => {
    const mediumSticky = { ...mockSticky, width: 2, height: 2 }
    const wrapper = mount(Calendar, {
      props: {
        sticky: mediumSticky
      }
    })

    // getScaleが0.95になっていることを確認（2x2は余白を最小限に）
    expect(wrapper.vm.getScale).toBe(0.95)
  })

  it('大サイズ（3x3）で適切なスケールが適用されること', () => {
    const largeSticky = { ...mockSticky, width: 3, height: 3 }
    const wrapper = mount(Calendar, {
      props: {
        sticky: largeSticky
      }
    })

    // getScaleが1.0になっていることを確認
    expect(wrapper.vm.getScale).toBe(1.0)
  })

  it('祝日attributesが定義されていること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // holidayAttributesが存在することを確認
    expect(wrapper.vm.holidayAttributes).toBeDefined()
  })

  it('現在の年月が追跡されていること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // currentYearとcurrentMonthが存在することを確認
    expect(wrapper.vm.currentYear).toBeDefined()
    expect(wrapper.vm.currentMonth).toBeDefined()
    expect(typeof wrapper.vm.currentYear).toBe('number')
    expect(typeof wrapper.vm.currentMonth).toBe('number')
  })

  it('updatePagesメソッドが年月を正しく更新すること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // updatePages メソッドを呼び出して月を変更
    const testPages = [{
      year: 2025,
      month: 5
    }]

    // 直接メソッドを呼び出して動作を確認
    wrapper.vm.updatePages(testPages)

    // updatePages が値を正しく設定することを確認
    // （VCalendar の自動更新前に即座にチェック）
    expect(wrapper.vm.currentYear).toBe(2025)
    expect(wrapper.vm.currentMonth).toBe(5)
  })

  it('日本語locale設定が適用されていること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // localeConfigが定義されていることを確認
    expect(wrapper.vm.localeConfig).toBeDefined()
    expect(wrapper.vm.localeConfig.firstDayOfWeek).toBe(0) // 日曜日始まり
  })

  it('年月表示フォーマットが日本語形式（YYYY年 M月）であること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // masksのtitleが「YYYY年 M月」形式であることを確認
    expect(wrapper.vm.localeConfig.masks).toBeDefined()
    expect(wrapper.vm.localeConfig.masks.title).toBe('YYYY年 M月')
  })

  it('今日の日付用のattributeが定義されていること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    // todayAttributeが存在することを確認
    expect(wrapper.vm.todayAttribute).toBeDefined()
    expect(Array.isArray(wrapper.vm.todayAttribute)).toBe(true)
    expect(wrapper.vm.todayAttribute.length).toBeGreaterThan(0)
  })

  it('今日の日付用のattributeに適切なハイライト設定があること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    const todayAttr = wrapper.vm.todayAttribute[0]

    // 基本プロパティの確認
    expect(todayAttr.key).toBe('today')
    expect(todayAttr.dates).toBeInstanceOf(Date)

    // ハイライト設定の確認
    expect(todayAttr.highlight).toBeDefined()
    expect(todayAttr.highlight.color).toBe('blue')
    expect(todayAttr.highlight.fillMode).toBe('solid')
    expect(todayAttr.highlight.class).toBe('today-highlight')
  })

  it('calendarAttributesに今日の日付が含まれていること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: mockSticky
      }
    })

    const calendarAttrs = wrapper.vm.calendarAttributes

    // calendarAttributesが配列であることを確認
    expect(Array.isArray(calendarAttrs)).toBe(true)

    // 今日の日付のattributeが含まれていることを確認
    const todayAttr = calendarAttrs.find(attr => attr.key === 'today')
    expect(todayAttr).toBeDefined()
    expect(todayAttr.highlight).toBeDefined()
  })

  it('title_visibleがtrueの場合、タイトルが表示されること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: { ...mockSticky, title: 'テストカレンダー', title_visible: true }
      }
    })

    expect(wrapper.vm.showTitle).toBe(true)
  })

  it('title_visibleがfalseの場合、タイトルが非表示になること', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: { ...mockSticky, title: 'テストカレンダー', title_visible: false }
      }
    })

    expect(wrapper.vm.showTitle).toBe(false)
  })

  it('toggleTitleVisibleがupdate-title-visibleイベントを発火すること', async () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: { ...mockSticky, title: 'テストカレンダー', title_visible: true }
      }
    })

    await wrapper.vm.toggleTitleVisible()

    expect(wrapper.emitted('update-title-visible')).toBeTruthy()
    expect(wrapper.emitted('update-title-visible')[0]).toEqual([1, false])
  })

  it('finishEditingTitleがupdate-titleイベントを発火すること', async () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: { ...mockSticky, title: 'テストカレンダー', title_visible: true }
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
