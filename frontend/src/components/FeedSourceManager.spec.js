import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import FeedSourceManager from './FeedSourceManager.vue'
import { useFeedSourceStore } from '@/stores/feedSource'
import { useStickyFeedSourceStore } from '@/stores/stickyFeedSource'

vi.mock('@/lib/apiClient')

describe('FeedSourceManager', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('レンダリングできること', () => {
    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('フィードソース一覧を表示すること', async () => {
    const feedSourceStore = useFeedSourceStore()
    const stickyFeedSourceStore = useStickyFeedSourceStore()

    feedSourceStore.fetchFeedSources = vi.fn().mockResolvedValue()
    feedSourceStore.feedSources = [
      { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' },
      { id: 2, title: 'Zenn', url: 'https://zenn.dev/feed' }
    ]

    stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()

    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })

    await wrapper.vm.$nextTick()
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('DEV Community')
    expect(wrapper.text()).toContain('Zenn')
  })

  it('選択済みのフィードソースにチェックが入ること', async () => {
    const feedSourceStore = useFeedSourceStore()
    const stickyFeedSourceStore = useStickyFeedSourceStore()

    feedSourceStore.fetchFeedSources = vi.fn().mockResolvedValue()
    feedSourceStore.feedSources = [
      { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' },
      { id: 2, title: 'Zenn', url: 'https://zenn.dev/feed' }
    ]

    stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
    stickyFeedSourceStore.stickyFeedSources = [
      {
        id: 1,
        sticky_id: 1,
        feed_source_id: 1,
        feed_source: { id: 1, title: 'DEV Community' }
      }
    ]

    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })

    await wrapper.vm.$nextTick()
    await wrapper.vm.$nextTick()

    const checkboxes = wrapper.findAll('[role="checkbox"]')
    expect(checkboxes.length).toBeGreaterThan(0)
  })

  it('Checkboxをクリックしてフィードソースを追加できること', async () => {
    const feedSourceStore = useFeedSourceStore()
    const stickyFeedSourceStore = useStickyFeedSourceStore()

    feedSourceStore.fetchFeedSources = vi.fn().mockResolvedValue()
    feedSourceStore.feedSources = [
      { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' }
    ]

    stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
    stickyFeedSourceStore.stickyFeedSources = []
    stickyFeedSourceStore.createStickyFeedSource = vi.fn().mockResolvedValue(true)

    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })

    await wrapper.vm.$nextTick()
    await wrapper.vm.$nextTick()

    // フィードソースを選択
    const checkboxWrapper = wrapper.findComponent({ name: 'Checkbox' })
    await checkboxWrapper.vm.$emit('update:modelValue', true)

    expect(stickyFeedSourceStore.createStickyFeedSource).toHaveBeenCalledWith(1, 1)
  })

  it('Checkboxをクリックしてフィードソースを削除できること', async () => {
    const feedSourceStore = useFeedSourceStore()
    const stickyFeedSourceStore = useStickyFeedSourceStore()

    feedSourceStore.fetchFeedSources = vi.fn().mockResolvedValue()
    feedSourceStore.feedSources = [
      { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' }
    ]

    stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
    stickyFeedSourceStore.stickyFeedSources = [
      {
        id: 10,
        sticky_id: 1,
        feed_source_id: 1,
        feed_source: { id: 1, title: 'DEV Community' }
      }
    ]

    stickyFeedSourceStore.deleteStickyFeedSource = vi.fn().mockResolvedValue(true)

    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })

    await wrapper.vm.$nextTick()
    await wrapper.vm.$nextTick()

    // フィードソースの選択を解除
    const checkboxWrapper = wrapper.findComponent({ name: 'Checkbox' })
    await checkboxWrapper.vm.$emit('update:modelValue', false)

    expect(stickyFeedSourceStore.deleteStickyFeedSource).toHaveBeenCalledWith(1, 10)
  })

  it('updatedイベントを発火すること', async () => {
    const feedSourceStore = useFeedSourceStore()
    const stickyFeedSourceStore = useStickyFeedSourceStore()

    feedSourceStore.fetchFeedSources = vi.fn().mockResolvedValue()
    feedSourceStore.feedSources = [
      { id: 1, title: 'DEV Community', url: 'https://dev.to/feed' }
    ]

    stickyFeedSourceStore.fetchStickyFeedSources = vi.fn().mockResolvedValue()
    stickyFeedSourceStore.stickyFeedSources = []
    stickyFeedSourceStore.createStickyFeedSource = vi.fn().mockResolvedValue(true)

    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })

    await wrapper.vm.$nextTick()
    await wrapper.vm.$nextTick()

    // フィードソースを選択
    const checkboxWrapper = wrapper.findComponent({ name: 'Checkbox' })
    await checkboxWrapper.vm.$emit('update:modelValue', true)

    // updatedイベントが発火されることを確認
    await wrapper.vm.$nextTick()
    expect(wrapper.emitted('updated')).toBeTruthy()
  })

  it('フィードソースがない場合はメッセージを表示すること', () => {
    const feedSourceStore = useFeedSourceStore()
    feedSourceStore.fetchFeedSources = vi.fn().mockResolvedValue()
    feedSourceStore.feedSources = []

    const wrapper = mount(FeedSourceManager, {
      props: {
        stickyId: 1
      }
    })

    expect(wrapper.text()).toContain('フィードがありません')
  })

})
