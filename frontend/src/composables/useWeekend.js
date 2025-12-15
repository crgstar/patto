import { computed } from 'vue'

/**
 * カレンダーの土日に背景色を適用する Composable
 * v-calendar の repeat patterns 機能を使用して毎週の土日を指定
 *
 * @returns {{ weekendAttributes: ComputedRef<Array> }} v-calendar 用の土日 attributes
 */
export function useWeekend() {
  // 土日の attributes を v-calendar 形式で返す
  const weekendAttributes = computed(() => {
    return [
      {
        // 毎週日曜日
        // weekdays: 1 = 日曜日
        dates: { repeat: { weekdays: 1 } },
        // 薄い青色の背景
        highlight: {
          color: 'blue',
          fillMode: 'light'
        },
        customData: {
          isWeekend: true,
          day: 'sunday'
        }
      },
      {
        // 毎週土曜日
        // weekdays: 7 = 土曜日
        dates: { repeat: { weekdays: 7 } },
        // 薄い青色の背景
        highlight: {
          color: 'blue',
          fillMode: 'light'
        },
        customData: {
          isWeekend: true,
          day: 'saturday'
        }
      }
    ]
  })

  return {
    weekendAttributes
  }
}
