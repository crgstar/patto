import { computed } from 'vue'
import HolidayJp from '@holiday-jp/holiday_jp'

/**
 * 日本の祝日を取得し、v-calendar の attributes 形式に変換する Composable
 *
 * @param {Ref<number>} year - 年（リアクティブ）
 * @param {Ref<number>} month - 月（リアクティブ、1-12）
 * @returns {{ holidayAttributes: ComputedRef<Array> }} v-calendar 用の祝日 attributes
 */
export function useHolidays(year, month) {
  // 指定された年月の祝日を v-calendar の attributes 形式で返す
  const holidayAttributes = computed(() => {
    // 月の最初の日と最後の日を計算
    const startDate = new Date(year.value, month.value - 1, 1)
    const endDate = new Date(year.value, month.value, 0)

    // 指定期間内の祝日を取得
    const holidays = HolidayJp.between(startDate, endDate)

    const attributes = []

    // 祝日のattributesを追加
    holidays.forEach(holiday => {
      attributes.push({
        dates: holiday.date,
        // バックグラウンドに薄い赤色を表示
        highlight: {
          color: 'red',
          fillMode: 'light'
        },
        // ホバー時に祝日名を表示
        popover: {
          label: holiday.name,
          visibility: 'hover'
        },
        customData: {
          isHoliday: true
        }
      })
    })

    return attributes
  })

  return {
    holidayAttributes
  }
}
