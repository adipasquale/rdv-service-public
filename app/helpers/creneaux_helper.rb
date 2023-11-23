module CreneauxHelper
  COLORS = %w[
    color-scheme-bleu
    color-scheme-orange
    color-scheme-green
    color-scheme-pink
    color-scheme-indigo
    color-scheme-turquoise
    color-scheme-yellow
    color-scheme-purple
    color-scheme-lightturquoise
    color-scheme-red
    color-scheme-teal
  ].freeze
  def agent_color(color_index)
    COLORS[color_index || (0 % COLORS.length)]
  end

  def creneaux_search_params(form)
    {
      service_id: form.service_id,
      motif_criteria: form.motif_criteria,
      from_date: form.from_date,
      agent_ids: form.agent_ids,
      team_ids: form.team_ids,
      user_ids: form.user_ids,
      lieu_ids: form.lieu_ids,
      context: form.context,
    }
  end

  def build_agent_creneaux_search_form(organisation, params)
    motif_criteria = case params[:motif_criteria]
                     when nil
                       nil
                     when String
                       params[:motif_criteria]
                     else
                       params[:motif_criteria].to_json
                     end
    AgentCreneauxSearchForm.new(
      organisation_id: organisation.id,
      service_id: params[:service_id],
      motif_criteria_json: motif_criteria,
      from_date: params[:from_date],
      context: params[:context].presence,
      user_ids: params.fetch(:user_ids, []).compact_blank,
      team_ids: params.fetch(:team_ids, []).compact_blank,
      agent_ids: params.fetch(:agent_ids, []).compact_blank,
      lieu_ids: params.fetch(:lieu_ids, []).compact_blank
    )
  end
end
