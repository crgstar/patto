<script setup>
import { Moon, Sun } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useTheme } from '@/composables/useTheme'

const { isDark, toggleTheme } = useTheme()
</script>

<template>
  <Button
    @click="toggleTheme"
    variant="ghost"
    size="icon"
    class="rounded-full hover:bg-accent/10 transition-all"
    :aria-label="isDark ? 'ライトモードに切り替え' : 'ダークモードに切り替え'"
  >
    <Sun
      v-if="isDark"
      class="h-5 w-5 text-foreground transition-all rotate-0 scale-100"
    />
    <Moon
      v-else
      class="h-5 w-5 text-foreground transition-all rotate-0 scale-100"
    />
  </Button>
</template>
