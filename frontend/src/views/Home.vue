<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

const router = useRouter()
const authStore = useAuthStore()

onMounted(async () => {
  const success = await authStore.fetchCurrentUser()
  if (!success) {
    router.push('/login')
  }
})

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-4">
    <div class="max-w-4xl mx-auto">
      <Card class="mb-4">
        <CardHeader class="flex flex-row items-center justify-between">
          <CardTitle>ダッシュボード</CardTitle>
          <Button @click="handleLogout" variant="outline">
            ログアウト
          </Button>
        </CardHeader>
        <CardContent>
          <div v-if="authStore.user" class="space-y-2">
            <p class="text-sm text-slate-600">ログイン中のユーザー</p>
            <p class="text-lg font-semibold">{{ authStore.user.email }}</p>
          </div>
          <div v-else class="text-center text-slate-500">
            ユーザー情報を読み込み中...
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>
