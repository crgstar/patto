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
const passwordConfirmation = ref('')

const handleSignup = async () => {
  const success = await authStore.signup(email.value, password.value, passwordConfirmation.value)

  if (success) {
    router.push('/')
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-50 p-4">
    <Card class="w-full max-w-md">
      <CardHeader>
        <CardTitle class="text-2xl">サインアップ</CardTitle>
        <CardDescription>アカウントを作成してください</CardDescription>
      </CardHeader>

      <CardContent class="space-y-4">
        <div v-if="authStore.error" class="p-3 text-sm text-red-600 bg-red-50 rounded-md border border-red-200">
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
            @keyup.enter="handleSignup"
          />
        </div>

        <div class="space-y-2">
          <Label for="password">パスワード</Label>
          <Input
            id="password"
            v-model="password"
            type="password"
            placeholder="6文字以上"
            required
            @keyup.enter="handleSignup"
          />
        </div>

        <div class="space-y-2">
          <Label for="password-confirmation">パスワード確認</Label>
          <Input
            id="password-confirmation"
            v-model="passwordConfirmation"
            type="password"
            placeholder="パスワードを再入力"
            required
            @keyup.enter="handleSignup"
          />
        </div>
      </CardContent>

      <CardFooter class="flex flex-col space-y-4">
        <Button
          @click="handleSignup"
          :disabled="authStore.loading"
          class="w-full"
        >
          {{ authStore.loading ? 'サインアップ中...' : 'サインアップ' }}
        </Button>

        <p class="text-sm text-center text-slate-600">
          すでにアカウントをお持ちの方は
          <router-link to="/login" class="text-blue-600 hover:underline">
            ログイン
          </router-link>
        </p>
      </CardFooter>
    </Card>
  </div>
</template>
