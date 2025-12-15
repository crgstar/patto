<script setup>
import { computed, ref } from 'vue'
import { Calendar as VCalendar } from 'v-calendar'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { MoreVertical, Trash2 } from 'lucide-vue-next'
import { useTheme } from '@/composables/useTheme'
import { useHolidays } from '@/composables/useHolidays'
import { useWeekend } from '@/composables/useWeekend'
import 'v-calendar/style.css'

const { isDark } = useTheme()

// 現在表示中の年月を追跡
const currentYear = ref(new Date().getFullYear())
const currentMonth = ref(new Date().getMonth() + 1) // JavaScriptのDateは0-11なので+1

// 祝日データを取得
const { holidayAttributes } = useHolidays(currentYear, currentMonth)

// 土日データを取得（repeatパターンを使用するため年月指定不要）
const { weekendAttributes } = useWeekend()

// 祝日と土日の attributes を結合
const calendarAttributes = computed(() => {
  return [...weekendAttributes.value, ...holidayAttributes.value]
})

const props = defineProps({
  sticky: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['delete'])

// サイズに基づいてスケールを計算
const getScale = computed(() => {
  const minDimension = Math.min(props.sticky.width, props.sticky.height)

  // 最小サイズに基づいてスケールを調整
  if (minDimension === 1) {
    return 0.4  // 1x1, 1x2など: 極小
  } else if (minDimension === 2) {
    return 0.95  // 2x2: 余白を最小限に
  } else {
    return 1.0  // 3x3以上: 標準
  }
})

// VCalendarの設定
const calendarConfig = computed(() => {
  const minDimension = Math.min(props.sticky.width, props.sticky.height)

  return {
    titlePosition: 'left',
    isExpanded: true,
    navVisibility: minDimension === 1 ? 'hidden' : 'focus',
    borderless: true,
    transparent: true
  }
})

const handleDelete = () => {
  emit('delete', props.sticky.id)
}

// カレンダーの月が変更された時に年月を更新
const updatePages = (pages) => {
  if (pages && pages.length > 0) {
    currentYear.value = pages[0].year
    currentMonth.value = pages[0].month
  }
}
</script>

<template>
  <Card
    class="group bg-card border-border shadow-sm hover:shadow-md hover:border-accent/50 transition-all h-full overflow-hidden relative"
  >
    <!-- 削除ボタン（右上に配置） -->
    <div class="absolute top-1 right-1 z-10 opacity-0 group-hover:opacity-100 transition-opacity">
      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <Button
            variant="ghost"
            size="icon"
            class="h-6 w-6 hover:bg-accent/10 p-0 rounded-full bg-background/80 backdrop-blur-sm"
          >
            <MoreVertical class="h-3.5 w-3.5" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem
            @click="handleDelete"
            data-testid="delete-calendar-button"
            class="text-destructive focus:text-destructive"
          >
            <Trash2 class="mr-2 h-4 w-4" />
            削除
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>

    <!-- カレンダー表示（正方形を強制） -->
    <div class="w-full h-full flex items-center justify-center p-0.5">
      <div
        class="calendar-container"
        :style="{
          transform: `scale(${getScale})`,
          transformOrigin: 'center center'
        }"
        data-testid="vcalendar"
      >
        <VCalendar
          :title-position="calendarConfig.titlePosition"
          :is-expanded="calendarConfig.isExpanded"
          :nav-visibility="calendarConfig.navVisibility"
          :borderless="calendarConfig.borderless"
          :transparent="calendarConfig.transparent"
          :is-dark="isDark"
          :attributes="calendarAttributes"
          @update:pages="updatePages"
          class="custom-calendar"
        />
      </div>
    </div>
  </Card>
</template>

<style scoped>
.calendar-container {
  /* width: 280px; */
  max-width: 100%;
  /* display: flex; */
  align-items: center;
  justify-content: center;
}

/* VCalendarのカスタムスタイル */
:deep(.custom-calendar) {
  /* width: 100%; */
  /* font-family: inherit; */
}

/* コンパクトなスタイル調整 - 余白を極力小さく、左右均等に */
:deep(.custom-calendar .vc-header) {
  /* padding: 0.125rem; */
}

:deep(.custom-calendar .vc-weeks) {
  /* padding: 0; */
}

:deep(.custom-calendar .vc-weekday) {
  /* font-size: 0.7rem; */
  padding: 0;
}

:deep(.custom-calendar .vc-day) {
  /* font-size: 0.75rem; */
  min-height: 22px;
}

:deep(.custom-calendar .vc-day-content) {
  width: 22px;
  /* height: 22px; */
  font-size: 0.8rem;
}

/* v-calendarの公式ダークモード（is-dark prop）を使用 */
/* 追加のカスタマイズが必要な場合はここに記述 */
</style>
