# フロントエンド オンボーディングガイド

このドキュメントは、Vue.jsにあまり詳しくない開発者向けに、Pattoプロジェクトのフロントエンド開発を始めるためのステップバイステップガイドです。

## 目次

1. [前提知識](#前提知識)
2. [技術スタック概要](#技術スタック概要)
3. [学習ステップ](#学習ステップ)
4. [プロジェクト構造](#プロジェクト構造)
5. [主要な概念](#主要な概念)
6. [開発フロー](#開発フロー)
7. [よくある質問](#よくある質問)

---

## 前提知識

このプロジェクトに取り組む前に、以下の基礎知識があると理解がスムーズです：

- **必須**
  - HTML/CSS/JavaScriptの基本
  - ES6以降のJavaScript（アロー関数、分割代入、モジュールなど）
  - 非同期処理（async/await、Promise）の基本

- **あると望ましい**
  - コンポーネント指向の考え方
  - REST APIの基本概念

---

## 技術スタック概要

Pattoフロントエンドで使用している主要な技術：

| 技術 | 用途 | 公式ドキュメント |
|------|------|-----------------|
| **Vue.js 3** | UIフレームワーク | https://ja.vuejs.org/ |
| **Composition API** | Vue 3の新しいAPI（`<script setup>`構文） | https://ja.vuejs.org/guide/extras/composition-api-faq.html |
| **Vite** | 高速なビルドツール | https://ja.vitejs.dev/ |
| **Vue Router** | ルーティング（ページ遷移） | https://router.vuejs.org/ |
| **Pinia** | 状態管理（グローバルデータ管理） | https://pinia.vuejs.org/ |
| **Tailwind CSS** | ユーティリティファーストなCSSフレームワーク | https://tailwindcss.com/ |
| **Radix Vue (reka-ui)** | アクセシブルなUIコンポーネント | https://www.radix-vue.com/ |
| **Axios** | HTTP通信ライブラリ | https://axios-http.com/ |
| **Vitest** | テストフレームワーク | https://vitest.dev/ |

---

## 学習ステップ

### ステップ1: Vue.js の基礎を学ぶ（2〜3日）

1. **Vue.js 公式チュートリアルを完了する**
   - https://ja.vuejs.org/tutorial/
   - `<script setup>`構文に注目してください（Pattoで使用）

2. **重要な概念を理解する**
   - リアクティビティ（`ref`, `computed`）
   - テンプレート構文（`v-if`, `v-for`, `v-model`など）
   - イベントハンドリング（`@click`など）
   - コンポーネントとprops/emit

3. **推奨リソース**
   - [Vue.js公式ガイド](https://ja.vuejs.org/guide/introduction.html)
   - [Composition APIガイド](https://ja.vuejs.org/guide/extras/composition-api-faq.html)

### ステップ2: プロジェクトのセットアップと動作確認（1日）

1. **環境構築**
   ```bash
   # プロジェクトのルートで
   cd frontend
   npm install
   ```

2. **開発サーバーを起動**
   ```bash
   npm run dev
   # http://localhost:5173 にアクセス
   ```

3. **テストを実行**
   ```bash
   npm run test        # 単体テスト
   npm run test:ui     # テストUIで実行
   ```

4. **ブラウザの開発者ツールを設定**
   - [Vue DevTools](https://devtools.vuejs.org/)をインストール

### ステップ3: プロジェクト構造を把握する（1〜2日）

以下の順番でコードを読んでいくことを推奨します：

1. **エントリーポイントを理解**
   - `frontend/src/main.js` - アプリケーションの起動ファイル
   - `frontend/src/App.vue` - ルートコンポーネント

2. **ルーティングを理解**
   - `frontend/src/router/index.js` - ページ遷移の定義

3. **シンプルなページから読む**
   - `frontend/src/views/Login.vue` - ログインページ（フォームとバリデーション）
   - `frontend/src/views/Signup.vue` - サインアップページ

4. **状態管理を理解**
   - `frontend/src/stores/auth.js` - 認証状態の管理（比較的シンプル）
   - `frontend/src/stores/sticky.js` - 付箋データの管理（やや複雑）

5. **UIコンポーネントを見る**
   - `frontend/src/components/ui/button/Button.vue` - シンプルなボタンコンポーネント
   - `frontend/src/components/Checklist.vue` - チェックリストコンポーネント

6. **メインページを理解**
   - `frontend/src/views/Home.vue` - アプリのメインページ（統合的な内容）

### ステップ4: 主要な技術を追加学習（2〜3日）

1. **Vue Router**
   - ページ遷移、ルートガード（認証チェック）の仕組みを学ぶ
   - `frontend/src/router/index.js:38-48` の `beforeEach` を読む

2. **Pinia（状態管理）**
   - [Pinia公式ガイド](https://pinia.vuejs.org/introduction.html)
   - グローバルな状態をどう管理するか理解する
   - `defineStore`, `ref`, `computed` の使い方

3. **Tailwind CSS**
   - [Tailwind CSS公式ドキュメント](https://tailwindcss.com/docs)
   - ユーティリティクラスの考え方に慣れる
   - `className="flex items-center gap-2"` のような書き方

4. **Composables（再利用可能なロジック）**
   - `frontend/src/composables/useTheme.js` - テーマ切り替え
   - `frontend/src/composables/useHolidays.js` - 祝日判定
   - Vue 3の推奨パターン

### ステップ5: 小さな機能を実装してみる（2〜3日）

実践的な学習として、以下のような小さなタスクに取り組むことを推奨：

1. **UIの軽微な変更**
   - ボタンの色を変える
   - テキストを変更する
   - アイコンを差し替える

2. **新しいページを作成**
   - `/about` ページを追加
   - ルーターに登録
   - ヘッダーにリンクを追加

3. **新しいUIコンポーネントを作成**
   - 既存の `components/ui` を参考に
   - 簡単なコンポーネント（Badge、Tag など）

4. **ストアに機能追加**
   - 既存のストアにgetterやactionを追加
   - データのフィルタリングや検索機能

---

## プロジェクト構造

```
frontend/
├── src/
│   ├── main.js                 # アプリケーションのエントリーポイント
│   ├── App.vue                 # ルートコンポーネント
│   ├── style.css               # グローバルスタイル（Tailwind設定）
│   │
│   ├── views/                  # ページコンポーネント（ルーティング対象）
│   │   ├── Home.vue            # メインページ（付箋一覧・グリッド）
│   │   ├── Login.vue           # ログインページ
│   │   ├── Signup.vue          # サインアップページ
│   │   └── Settings.vue        # 設定ページ（フィード管理）
│   │
│   ├── components/             # 再利用可能なコンポーネント
│   │   ├── Calendar.vue        # カレンダーコンポーネント
│   │   ├── Checklist.vue       # チェックリストコンポーネント
│   │   ├── FeedReader.vue      # フィードリーダーコンポーネント
│   │   ├── GridLayout.vue      # グリッドレイアウト（付箋配置）
│   │   └── ui/                 # UIプリミティブ（shadcn/ui風）
│   │       ├── button/         # ボタンコンポーネント
│   │       ├── card/           # カードコンポーネント
│   │       ├── dialog/         # ダイアログコンポーネント
│   │       └── ...
│   │
│   ├── stores/                 # Piniaストア（状態管理）
│   │   ├── auth.js             # 認証状態（ログイン情報など）
│   │   ├── sticky.js           # 付箋データ管理
│   │   ├── feedSource.js       # フィード元管理
│   │   └── feedItem.js         # フィードアイテム管理
│   │
│   ├── composables/            # 再利用可能なロジック（Vue Composables）
│   │   ├── useTheme.js         # テーマ切り替え（ダーク/ライト）
│   │   ├── useHolidays.js      # 日本の祝日判定
│   │   └── useWeekend.js       # 週末判定
│   │
│   ├── router/                 # Vue Routerの設定
│   │   └── index.js            # ルート定義・ナビゲーションガード
│   │
│   └── lib/                    # ユーティリティ関数
│       ├── apiClient.js        # Axiosインスタンス（API通信）
│       └── utils.js            # 汎用ヘルパー関数（cn関数など）
│
├── vite.config.js              # Viteの設定
├── tailwind.config.js          # Tailwind CSSの設定
└── package.json                # 依存関係とスクリプト
```

### ディレクトリの役割

| ディレクトリ | 役割 | 例 |
|------------|------|-----|
| `views/` | ページ全体を表すコンポーネント | Home, Login, Settings |
| `components/` | 再利用可能なUIパーツ | Calendar, Checklist, Button |
| `stores/` | グローバルな状態管理 | 認証情報、付箋データ |
| `composables/` | ロジックの再利用 | テーマ管理、祝日判定 |
| `router/` | ページ遷移の設定 | URL → コンポーネントのマッピング |
| `lib/` | ヘルパー関数・ユーティリティ | API通信、CSS結合 |

---

## 主要な概念

### 1. Composition API と `<script setup>`

Pattoでは、Vue 3の**Composition API**を`<script setup>`構文で使用しています。

**基本構造:**

```vue
<script setup>
import { ref, computed, onMounted } from 'vue'

// リアクティブな変数
const count = ref(0)

// 算出プロパティ
const doubleCount = computed(() => count.value * 2)

// 関数
const increment = () => {
  count.value++
}

// ライフサイクルフック
onMounted(() => {
  console.log('コンポーネントがマウントされました')
})
</script>

<template>
  <div>
    <p>カウント: {{ count }}</p>
    <p>2倍: {{ doubleCount }}</p>
    <button @click="increment">増やす</button>
  </div>
</template>
```

**重要なポイント:**
- `ref()` でリアクティブな変数を作る（JavaScriptでは `.value` でアクセス）
- `computed()` で算出プロパティを作る（依存する値が変わると自動更新）
- テンプレート内では `.value` は不要

### 2. Props と Emit（コンポーネント間の通信）

**Props: 親から子へデータを渡す**

```vue
<!-- 親コンポーネント -->
<ChildComponent :message="hello" :count="10" />

<!-- 子コンポーネント -->
<script setup>
const props = defineProps({
  message: String,
  count: Number
})
</script>
```

**Emit: 子から親へイベントを通知**

```vue
<!-- 子コンポーネント -->
<script setup>
const emit = defineEmits(['update', 'delete'])

const handleClick = () => {
  emit('update', { id: 1, value: 'new value' })
}
</script>

<!-- 親コンポーネント -->
<ChildComponent @update="handleUpdate" @delete="handleDelete" />
```

**Pattoでの例:**

`frontend/src/components/Checklist.vue` が子コンポーネント、`frontend/src/views/Home.vue` が親コンポーネント

```vue
<!-- Home.vue（親） -->
<Checklist
  :checklist="item.sticky"
  @add-item="handleAddChecklistItem"
  @delete="deleteChecklist"
/>
```

### 3. Pinia ストア（状態管理）

複数のコンポーネントで共有したいデータは、**Piniaストア**で管理します。

**ストアの定義例（`stores/auth.js`）:**

```javascript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // 状態
  const user = ref(null)

  // 算出プロパティ
  const isAuthenticated = computed(() => user.value !== null)

  // アクション（非同期処理など）
  const login = async (email, password) => {
    // API呼び出し
    const response = await apiClient.post('/login', { email, password })
    user.value = response.data.user
  }

  return { user, isAuthenticated, login }
})
```

**コンポーネントでの使用:**

```vue
<script setup>
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

// 状態を参照
console.log(authStore.user)
console.log(authStore.isAuthenticated)

// アクションを実行
await authStore.login('user@example.com', 'password')
</script>
```

### 4. Vue Router（ルーティング）

ページ遷移を管理します。

**ルート定義（`router/index.js`）:**

```javascript
const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue'),
    meta: { requiresAuth: true }  // 認証が必要
  },
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresAuth: false }
  }
]
```

**ナビゲーションガード（認証チェック）:**

```javascript
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')  // ログインページにリダイレクト
  } else {
    next()  // そのまま進む
  }
})
```

**コンポーネントでページ遷移:**

```vue
<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const goToSettings = () => {
  router.push('/settings')
}
</script>

<template>
  <button @click="goToSettings">設定へ</button>
  <!-- または -->
  <RouterLink to="/settings">設定へ</RouterLink>
</template>
```

### 5. API通信（Axios）

バックエンドAPIとの通信は `lib/apiClient.js` で行います。

**APIクライアントの設定:**

```javascript
// lib/apiClient.js
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api',
  withCredentials: true  // Cookieを送信
})

export default apiClient
```

**ストアでの使用例:**

```javascript
// stores/sticky.js
import apiClient from '@/lib/apiClient'

const fetchStickies = async () => {
  const response = await apiClient.get('/stickies')
  stickies.value = response.data.stickies
}

const createSticky = async (stickyData) => {
  const response = await apiClient.post('/stickies', {
    sticky: stickyData
  })
  stickies.value.push(response.data.sticky)
}
```

### 6. Composables（再利用可能なロジック）

複数のコンポーネントで使いたいロジックを切り出したもの。

**例: テーマ切り替え（`composables/useTheme.js`）:**

```javascript
import { ref, watch, onMounted } from 'vue'

export function useTheme() {
  const theme = ref(localStorage.getItem('theme') || 'light')

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
  }

  watch(theme, (newTheme) => {
    document.documentElement.classList.toggle('dark', newTheme === 'dark')
    localStorage.setItem('theme', newTheme)
  })

  onMounted(() => {
    document.documentElement.classList.toggle('dark', theme.value === 'dark')
  })

  return { theme, toggleTheme }
}
```

**コンポーネントでの使用:**

```vue
<script setup>
import { useTheme } from '@/composables/useTheme'

const { theme, toggleTheme } = useTheme()
</script>

<template>
  <button @click="toggleTheme">
    現在: {{ theme }}
  </button>
</template>
```

---

## 開発フロー

### 1. 新機能開発の典型的な流れ

1. **要件を理解する**
   - どのような機能を追加するか
   - どのコンポーネントに影響するか

2. **UIコンポーネントを作成/修正**
   - `components/` にコンポーネントを作成
   - テンプレート、スタイル、ロジックを実装

3. **ストアを作成/修正**
   - グローバルな状態が必要なら `stores/` にストアを作成
   - API通信のロジックを追加

4. **ページに統合**
   - `views/` のページコンポーネントで組み合わせる

5. **ルーティングを追加（必要に応じて）**
   - `router/index.js` にルートを追加

6. **テストを書く**
   - `*.spec.js` ファイルを作成
   - `npm run test` で動作確認

### 2. デバッグ方法

**Vue DevTools を使う:**
- ブラウザ拡張機能をインストール
- コンポーネントツリー、状態、イベントを確認

**console.log を使う:**
```vue
<script setup>
const handleClick = () => {
  console.log('クリックされました')
  console.log('現在の状態:', someValue.value)
}
</script>
```

**ブレークポイントを使う:**
- ブラウザの開発者ツールの「Sources」タブ
- コードにブレークポイントを設定して実行を一時停止

### 3. よくあるエラーと解決法

| エラー | 原因 | 解決法 |
|-------|------|--------|
| `ref.value is not defined` | `ref()` の値に `.value` でアクセスしていない | JavaScriptでは `count.value` でアクセス |
| `Cannot read property of undefined` | データがまだ読み込まれていない | `v-if` で条件付きレンダリング |
| `Component is not registered` | コンポーネントをインポートしていない | `import MyComponent from '...'` |
| APIエラー（401, 403） | 認証トークンが無効 | ログインし直す、Cookieを確認 |

---

## よくある質問

### Q1: `ref()` と `reactive()` の違いは？

- **`ref()`**: プリミティブな値（数値、文字列、真偽値）や単一のオブジェクトに使う
  ```javascript
  const count = ref(0)
  count.value = 1
  ```

- **`reactive()`**: オブジェクト全体をリアクティブにする
  ```javascript
  const state = reactive({ count: 0, name: 'Alice' })
  state.count = 1
  ```

**推奨**: Pattoでは主に `ref()` を使用しています（Piniaストアでも同様）

### Q2: `computed` と `watch` の違いは？

- **`computed`**: 他の値から計算された値を作る（キャッシュされる）
  ```javascript
  const doubleCount = computed(() => count.value * 2)
  ```

- **`watch`**: 値が変わったときに副作用を実行する
  ```javascript
  watch(count, (newValue, oldValue) => {
    console.log(`${oldValue} から ${newValue} に変わりました`)
  })
  ```

### Q3: `@` って何？

`@` は `src/` ディレクトリのエイリアスです（`vite.config.js` で設定）

```javascript
// これらは同じ意味
import Button from '@/components/ui/button/Button.vue'
import Button from '../../../components/ui/button/Button.vue'
```

### Q4: Tailwind CSSのクラス名が長すぎて読みにくい

`cn()` ヘルパー関数を使うと、条件付きでクラスを追加できます：

```vue
<script setup>
import { cn } from '@/lib/utils'

const isActive = ref(true)
</script>

<template>
  <div :class="cn('text-base', isActive && 'font-bold', 'text-gray-900')">
    テキスト
  </div>
</template>
```

### Q5: テストはどう書けばいい？

既存のテストファイルを参考にしてください：

```javascript
// Calendar.spec.js の例
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Calendar from './Calendar.vue'

describe('Calendar', () => {
  it('カレンダーがレンダリングされる', () => {
    const wrapper = mount(Calendar, {
      props: {
        sticky: { id: 1, title: 'カレンダー' }
      }
    })
    expect(wrapper.text()).toContain('カレンダー')
  })
})
```

---

## 次のステップ

このガイドを読み終えたら：

1. **実際にコードを書いてみる**
   - 小さな変更から始める
   - エラーを恐れない

2. **公式ドキュメントを参照する**
   - Vue.js: https://ja.vuejs.org/
   - Pinia: https://pinia.vuejs.org/
   - Vue Router: https://router.vuejs.org/

3. **チームに質問する**
   - わからないことは積極的に聞く
   - コードレビューで学ぶ

4. **より高度な機能に挑戦**
   - カスタムディレクティブ
   - プラグインの作成
   - パフォーマンス最適化

---

**Happy Coding! 🚀**
