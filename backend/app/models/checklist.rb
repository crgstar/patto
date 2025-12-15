class Checklist < Sticky
  has_many :checklist_items,
           -> { order(position: :asc) },
           foreign_key: :sticky_id

  after_discard :discard_checklist_items

  def completed_count
    checklist_items.where(checked: true).count
  end

  def total_count
    checklist_items.count
  end

  def completion_percentage
    return 0 if total_count.zero?
    (completed_count.to_f / total_count * 100).round
  end

  private

  def discard_checklist_items
    checklist_items.each(&:discard)
  end
end
