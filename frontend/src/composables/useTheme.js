import { ref, watch, onMounted } from 'vue'

const THEME_KEY = 'patto-theme'
const THEME_LIGHT = 'light'
const THEME_DARK = 'dark'
const THEME_SYSTEM = 'system'

// グローバルなテーマ状態（アプリ全体で共有）
const theme = ref(THEME_SYSTEM)
const isDark = ref(false)

/**
 * システムのダークモード設定を取得
 */
const getSystemTheme = () => {
  if (typeof window === 'undefined') return false
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

/**
 * HTMLにdarkクラスを適用/削除
 */
const applyTheme = (dark) => {
  if (typeof document === 'undefined') return

  if (dark) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
}

/**
 * テーマを更新する
 */
const updateTheme = (newTheme) => {
  theme.value = newTheme

  // localStorageに保存
  if (typeof localStorage !== 'undefined') {
    localStorage.setItem(THEME_KEY, newTheme)
  }

  // 実際のdark状態を計算
  if (newTheme === THEME_SYSTEM) {
    isDark.value = getSystemTheme()
  } else {
    isDark.value = newTheme === THEME_DARK
  }

  // HTMLに適用
  applyTheme(isDark.value)
}

/**
 * テーマの初期化（localStorageから読み込み）
 */
const initTheme = () => {
  if (typeof localStorage === 'undefined') return

  const savedTheme = localStorage.getItem(THEME_KEY)
  if (savedTheme && [THEME_LIGHT, THEME_DARK, THEME_SYSTEM].includes(savedTheme)) {
    updateTheme(savedTheme)
  } else {
    // 初回はシステム設定に従う
    updateTheme(THEME_SYSTEM)
  }
}

/**
 * テーマ管理用のComposable
 */
export const useTheme = () => {
  // マウント時にテーマを初期化
  onMounted(() => {
    initTheme()

    // システムのテーマ変更を監視
    if (typeof window !== 'undefined') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
      const handleChange = (e) => {
        if (theme.value === THEME_SYSTEM) {
          isDark.value = e.matches
          applyTheme(e.matches)
        }
      }

      // モダンブラウザ用
      if (mediaQuery.addEventListener) {
        mediaQuery.addEventListener('change', handleChange)
      } else {
        // レガシーブラウザ用
        mediaQuery.addListener(handleChange)
      }
    }
  })

  /**
   * ライトモードに切り替え
   */
  const setLight = () => {
    updateTheme(THEME_LIGHT)
  }

  /**
   * ダークモードに切り替え
   */
  const setDark = () => {
    updateTheme(THEME_DARK)
  }

  /**
   * システム設定に従う
   */
  const setSystem = () => {
    updateTheme(THEME_SYSTEM)
  }

  /**
   * ライト/ダークをトグル
   */
  const toggleTheme = () => {
    if (theme.value === THEME_SYSTEM) {
      // システムモードの場合、現在の表示状態の逆にする
      updateTheme(isDark.value ? THEME_LIGHT : THEME_DARK)
    } else if (theme.value === THEME_LIGHT) {
      updateTheme(THEME_DARK)
    } else {
      updateTheme(THEME_LIGHT)
    }
  }

  return {
    theme,
    isDark,
    setLight,
    setDark,
    setSystem,
    toggleTheme,
  }
}

// アプリ起動時に即座にテーマを適用（フラッシュ防止）
if (typeof window !== 'undefined' && typeof localStorage !== 'undefined') {
  const savedTheme = localStorage.getItem(THEME_KEY)
  let shouldBeDark = false

  if (savedTheme === THEME_DARK) {
    shouldBeDark = true
  } else if (savedTheme === THEME_LIGHT) {
    shouldBeDark = false
  } else {
    // systemまたは未設定の場合
    shouldBeDark = getSystemTheme()
  }

  applyTheme(shouldBeDark)
}
