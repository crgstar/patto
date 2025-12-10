<script setup>
import { RouterView } from 'vue-router'
import { useTheme } from '@/composables/useTheme'

// アプリ起動時にテーマを初期化
useTheme()
</script>

<template>
  <RouterView />
</template>
