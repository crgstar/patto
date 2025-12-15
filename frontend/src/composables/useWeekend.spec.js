import { describe, it, expect } from 'vitest'
import { useWeekend } from './useWeekend'

describe('useWeekend', () => {
  it('土日の attributes が生成されること', () => {
    const { weekendAttributes } = useWeekend()

    const attrs = weekendAttributes.value
    expect(attrs).toBeDefined()
    expect(attrs.length).toBe(2) // 日曜日と土曜日の2つ
  })

  it('v-calendar の repeat pattern 形式に正しく変換されること', () => {
    const { weekendAttributes } = useWeekend()

    const attrs = weekendAttributes.value

    // 日曜日の attribute
    const sundayAttr = attrs.find(attr => attr.customData.day === 'sunday')
    expect(sundayAttr).toBeDefined()
    expect(sundayAttr.dates).toBeDefined()
    expect(sundayAttr.dates.repeat).toBeDefined()
    expect(sundayAttr.dates.repeat.weekdays).toBe(1) // 日曜日

    // 土曜日の attribute
    const saturdayAttr = attrs.find(attr => attr.customData.day === 'saturday')
    expect(saturdayAttr).toBeDefined()
    expect(saturdayAttr.dates).toBeDefined()
    expect(saturdayAttr.dates.repeat).toBeDefined()
    expect(saturdayAttr.dates.repeat.weekdays).toBe(7) // 土曜日
  })

  it('土日には青色の highlight が設定されること', () => {
    const { weekendAttributes } = useWeekend()

    const attrs = weekendAttributes.value

    // 全ての土日属性が青色の薄い背景色を持つこと
    attrs.forEach(attr => {
      expect(attr.highlight).toBeDefined()
      expect(attr.highlight.color).toBe('blue')
      expect(attr.highlight.fillMode).toBe('light')
    })
  })

  it('customData に isWeekend フラグが設定されること', () => {
    const { weekendAttributes } = useWeekend()

    const attrs = weekendAttributes.value

    attrs.forEach(attr => {
      expect(attr.customData).toBeDefined()
      expect(attr.customData.isWeekend).toBe(true)
    })
  })

  it('日曜日と土曜日がそれぞれ識別できること', () => {
    const { weekendAttributes } = useWeekend()

    const attrs = weekendAttributes.value

    const days = attrs.map(attr => attr.customData.day)
    expect(days).toContain('sunday')
    expect(days).toContain('saturday')
  })

  it('repeat pattern は weekdays 指定のみであること', () => {
    const { weekendAttributes } = useWeekend()

    const attrs = weekendAttributes.value

    attrs.forEach(attr => {
      expect(attr.dates.repeat).toBeDefined()
      expect(attr.dates.repeat.weekdays).toBeDefined()
      expect(typeof attr.dates.repeat.weekdays).toBe('number')
    })
  })

  it('attributes は常に同じ構造を返すこと（リアクティブだが内容は一定）', () => {
    const { weekendAttributes } = useWeekend()

    const attrs1 = weekendAttributes.value
    const attrs2 = weekendAttributes.value

    // 同じ構造であること
    expect(attrs1.length).toBe(attrs2.length)
    expect(attrs1[0].dates.repeat.weekdays).toBe(attrs2[0].dates.repeat.weekdays)
    expect(attrs1[1].dates.repeat.weekdays).toBe(attrs2[1].dates.repeat.weekdays)
  })
})
