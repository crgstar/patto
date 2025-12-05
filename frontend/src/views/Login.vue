<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')

const handleLogin = async () => {
  const success = await authStore.login(email.value, password.value)

  if (success) {
    router.push('/')
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-background p-4">
    <Card class="w-full max-w-md shadow-lg">
      <CardHeader>
        <CardTitle class="text-2xl">ログイン</CardTitle>
        <CardDescription>メールアドレスとパスワードを入力してください</CardDescription>
      </CardHeader>

      <CardContent class="space-y-4">
        <div v-if="authStore.error" class="p-3 text-sm text-destructive-foreground bg-destructive/10 rounded-md border border-destructive/30">
          {{ authStore.error }}
        </div>

        <div class="space-y-2">
          <Label for="email">メールアドレス</Label>
          <Input
            id="email"
            v-model="email"
            type="email"
            placeholder="name@example.com"
            required
            @keyup.enter="handleLogin"
          />
        </div>

        <div class="space-y-2">
          <Label for="password">パスワード</Label>
          <Input
            id="password"
            v-model="password"
            type="password"
            placeholder="パスワードを入力"
            required
            @keyup.enter="handleLogin"
          />
        </div>
      </CardContent>

      <CardFooter class="flex flex-col space-y-4">
        <Button
          @click="handleLogin"
          :disabled="authStore.loading"
          class="w-full"
        >
          {{ authStore.loading ? 'ログイン中...' : 'ログイン' }}
        </Button>

        <p class="text-sm text-center text-muted-foreground">
          アカウントをお持ちでない方は
          <router-link to="/signup" class="text-foreground hover:underline font-medium">
            サインアップ
          </router-link>
        </p>
      </CardFooter>
    </Card>
  </div>
</template>
