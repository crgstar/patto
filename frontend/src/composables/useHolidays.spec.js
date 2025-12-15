import { describe, it, expect } from 'vitest'
import { useHolidays } from './useHolidays'
import { ref } from 'vue'

describe('useHolidays', () => {
  it('2025年1月の祝日が取得できること（元日が含まれる）', () => {
    const year = ref(2025)
    const month = ref(1)
    const { holidayAttributes } = useHolidays(year, month)

    // 2025年1月1日は元日
    const holidays = holidayAttributes.value
    expect(holidays.length).toBeGreaterThan(0)

    // 元日の祝日が含まれていることを確認
    const newYearDay = holidays.find(h => h.dates.getDate() === 1)
    expect(newYearDay).toBeDefined()
    expect(newYearDay.popover.label).toBe('元日')
  })

  it('2025年5月のゴールデンウィーク祝日が取得できること（複数祝日）', () => {
    const year = ref(2025)
    const month = ref(5)
    const { holidayAttributes } = useHolidays(year, month)

    const attrs = holidayAttributes.value
    // 5月は祝日と土日が含まれる
    expect(attrs.length).toBeGreaterThan(0)

    // 祝日のみをフィルター
    const holidays = attrs.filter(attr => attr.customData && attr.customData.isHoliday)

    // 5月は複数の祝日がある（憲法記念日、みどりの日、こどもの日など）
    expect(holidays.length).toBeGreaterThanOrEqual(3)

    // 祝日名が正しく設定されていることを確認
    holidays.forEach(holiday => {
      expect(holiday.popover).toBeDefined()
      expect(holiday.popover.label).toBeTruthy()
    })
  })

  it('祝日がない月（6月）では空配列が返ること', () => {
    const year = ref(2025)
    const month = ref(6)
    const { holidayAttributes } = useHolidays(year, month)

    const attrs = holidayAttributes.value
    // 2025年6月は祝日がないため、空配列が返る
    expect(attrs.length).toBe(0)
  })

  it('v-calendar attributes形式に正しく変換されること（highlight使用）', () => {
    const year = ref(2025)
    const month = ref(1)
    const { holidayAttributes } = useHolidays(year, month)

    const attrs = holidayAttributes.value
    expect(attrs.length).toBeGreaterThan(0)

    // 各attributeが正しい形式になっていることを確認
    attrs.forEach(attr => {
      // dates プロパティが存在すること（Dateオブジェクト）
      expect(attr.dates).toBeDefined()
      expect(attr.dates).toBeInstanceOf(Date)

      // highlight プロパティが存在すること
      expect(attr.highlight).toBeDefined()
      expect(attr.highlight.color).toBeTruthy()
      expect(attr.highlight.fillMode).toBe('light')

      // customData が存在すること
      expect(attr.customData).toBeDefined()
      expect(attr.customData.isHoliday).toBe(true)
    })
  })

  it('祝日には赤色の highlight が設定されること', () => {
    const year = ref(2025)
    const month = ref(1)
    const { holidayAttributes } = useHolidays(year, month)

    const attrs = holidayAttributes.value

    // 祝日のattributesを探す（1月1日は元日）
    const holidayAttr = attrs.find(attr =>
      attr.customData && attr.customData.isHoliday
    )
    expect(holidayAttr).toBeDefined()
    // 祝日は赤系の色
    expect(holidayAttr.highlight.color).toContain('red')
    expect(holidayAttr.popover).toBeDefined()
    expect(holidayAttr.popover.label).toBeTruthy()
  })

  it('年月が変更されると祝日も更新されること', () => {
    const year = ref(2025)
    const month = ref(1)
    const { holidayAttributes } = useHolidays(year, month)

    // 最初は1月の祝日
    const januaryHolidays = holidayAttributes.value
    expect(januaryHolidays.length).toBeGreaterThan(0)

    // 月を5月に変更
    month.value = 5
    const mayHolidays = holidayAttributes.value

    // 祝日が更新されていることを確認
    expect(mayHolidays).not.toEqual(januaryHolidays)
    expect(mayHolidays.length).toBeGreaterThanOrEqual(3)
  })

  it('年が変更されても正しく動作すること', () => {
    const year = ref(2024)
    const month = ref(1)
    const { holidayAttributes } = useHolidays(year, month)

    // 2024年の祝日
    const holidays2024 = holidayAttributes.value
    expect(holidays2024.length).toBeGreaterThan(0)

    // 年を2025に変更
    year.value = 2025
    const holidays2025 = holidayAttributes.value

    // 祝日が存在することを確認（年によって祝日の日付が異なる可能性がある）
    expect(holidays2025.length).toBeGreaterThan(0)
  })
})
