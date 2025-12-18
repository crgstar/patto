import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import FeedReader from './FeedReader.vue'
import { useStickyFeedSourceStore } from '@/stores/stickyFeedSource'
import { useFeedItemStore } from '@/stores/feedItem'
import { useFeedSourceStore } from '@/stores/feedSource'

vi.mock('@/lib/apiClient')

describe('FeedReader', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('基本構造', () => {
    it('レンダリングできること', () => {
      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('propsを受け取ること', () => {
      const feedReaderProp = { id: 1, type: 'FeedReader', title: '', content: '' }
      const wrapper = mount(FeedReader, {
        props: {
          feedReader: feedReaderProp,
          width: 3,
          height: 3
        }
      })

      expect(wrapper.props('feedReader')).toEqual(feedReaderProp)
      expect(wrapper.props('width')).toBe(3)
      expect(wrapper.props('height')).toBe(3)
    })

    it('削除イベントを発火すること', async () => {
      const wrapper = mount(FeedReader, {
        props: {
          feedReader: { id: 1, type: 'FeedReader', title: '', content: '' },
          width: 3,
          height: 3
        }
      })

      // 削除ハンドラーを直接呼び出してテスト
      await wrapper.vm.handleDelete()

      expect(wrapper.emitted('delete')).toBeTruthy()
      expect(wrapper.emitted('delete')[0]).toEqual([1])
    })
  })
})
