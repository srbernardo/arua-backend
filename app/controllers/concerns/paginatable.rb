module Paginatable
  extend ActiveSupport::Concern

  MAX_PER_PAGE = 100
  DEFAULT_PER_PAGE = 20

  private

  def paginate(relation)
    page = [params[:page].to_i, 1].max
    per_page = params[:per_page].to_i
    per_page = DEFAULT_PER_PAGE if per_page <= 0
    per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

    total =
      if relation.group_values.present?
        relation.model.from(relation, :paginated).count
      elsif relation.select_values.present?
        relation.except(:select).count
      else
        relation.count
      end
    total_pages = total.zero? ? 0 : (total.to_f / per_page).ceil

    [
      relation.limit(per_page).offset((page - 1) * per_page),
      {
        page: page,
        per_page: per_page,
        total: total,
        total_pages: total_pages
      }
    ]
  end
end