defmodule SnippetSaverWeb.SettingLive.CatalogTableSupport do
  @moduledoc false
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [push_patch: 2]
  import Ecto.Query
  import LiveTable.Filter
  import LiveTable.Join
  import LiveTable.Paginate
  import LiveTable.Sorting
  import Debug, only: [debug_pipeline: 2]

  @repo Application.compile_env(:live_table, :repo)

  def list_resources(fields, options, schema, raw_table_options) do
    {regular_filters, transformers, debug_mode} = prepare_query_context(options, raw_table_options)

    schema
    |> from(as: :resource)
    |> join_associations(regular_filters)
    |> select_columns(fields)
    |> apply_filters(regular_filters, fields)
    |> maybe_sort(fields, options["sort"]["sort_params"], options["sort"]["sortable?"])
    |> apply_transformers(transformers)
    |> maybe_paginate(options["pagination"], options["pagination"]["paginate?"])
    |> debug_pipeline(debug_mode)
  end

  def stream_resources(fields, %{"pagination" => %{"paginate?" => true}} = options, schema, raw_table_options) do
    per_page = options["pagination"]["per_page"] |> String.to_integer()

    list_resources(fields, options, schema, raw_table_options)
    |> @repo.all()
    |> Enum.split(per_page)
  end

  def stream_resources(fields, %{"pagination" => %{"paginate?" => false}} = options, schema, raw_table_options) do
    list_resources(fields, options, schema, raw_table_options) |> @repo.all()
  end

  def get_merged_table_options(raw_table_options) do
    LiveTable.TableConfig.get_table_options(raw_table_options)
  end

  def apply_table_params(socket, params, uri, schema, table_module, get_filter_fn)
      when is_function(get_filter_fn, 1) do
    fields = table_module.fields()

    current_path =
      uri
      |> URI.parse()
      |> Map.get(:path, "")
      |> String.trim_leading("/")

    qs = uri |> URI.parse() |> Map.get(:query)
    table_query_string = if is_binary(qs), do: qs, else: ""

    opts = get_merged_table_options(table_module.table_options())
    default_sort = get_in(opts, [:sorting, :default_sort]) || [id: :asc]

    sort_params =
      case params["sort_params"] do
        nil -> default_sort
        %{} = m when map_size(m) == 0 -> default_sort
        other -> other
      end
      |> Enum.map(fn
        {k, v} when is_atom(k) and is_atom(v) -> {k, v}
        {k, v} -> {String.to_existing_atom(k), String.to_existing_atom(v)}
      end)

    filters =
      (params["filters"] || %{})
      |> Map.put("search", params["search"] || "")
      |> Enum.reduce(%{}, fn
        {"search", search_term}, acc ->
          Map.put(acc, "search", search_term)

        {k, _}, acc ->
          Map.put(acc, String.to_existing_atom(k), get_filter_fn.(k))
      end)

    options = %{
      "sort" => %{
        "sortable?" => get_in(opts, [:sorting, :enabled]),
        "sort_params" => sort_params
      },
      "pagination" => %{
        "paginate?" => get_in(opts, [:pagination, :enabled]),
        "page" => params["page"] || "1",
        "per_page" =>
          params["per_page"] || to_string(get_in(opts, [:pagination, :default_size]) || 10)
      },
      "filters" => filters
    }

    {resources, updated_options} =
      case stream_resources(fields, options, schema, table_module.table_options()) do
        {resources, overflow} ->
          options = put_in(options["pagination"][:has_next_page], length(overflow) > 0)
          {resources, options}

        resources when is_list(resources) ->
          {resources, options}
      end

    socket
    |> assign(:resources, resources)
    |> assign(:options, updated_options)
    |> assign(:current_path, current_path)
    |> assign(:table_query_string, table_query_string)
  end

  def handle_sort_clear(socket) do
    current_path = socket.assigns.current_path

    options =
      socket.assigns.options
      |> Enum.reduce(%{}, fn
        {"filters", _v}, acc ->
          Map.put(acc, "filters", %{})

        {_, v}, acc when is_map(v) ->
          Map.merge(acc, v)
      end)
      |> Map.take(~w(page per_page sort_params))
      |> Map.reject(fn {_, v} -> v == "" || is_nil(v) end)

    {:noreply, push_patch(socket, to: "/#{current_path}?#{Plug.Conn.Query.encode(options)}")}
  end

  defp prepare_query_context(options, raw_table_options) do
    debug_mode =
      Map.get(LiveTable.TableConfig.get_table_options(raw_table_options), :debug, :off)

    {regular_filters, transformers} =
      Map.get(options, "filters", nil)
      |> separate_filters_and_transformers()

    {regular_filters, transformers, debug_mode}
  end

  defp separate_filters_and_transformers(filters) when is_map(filters) do
    {transformers, regular_filters} =
      filters
      |> Enum.split_with(fn {_, filter} ->
        match?(%LiveTable.Transformer{}, filter)
      end)

    {Map.new(regular_filters), Map.new(transformers)}
  end

  defp separate_filters_and_transformers(nil), do: {%{}, %{}}

  defp apply_transformers(query, transformers) do
    Enum.reduce(transformers, query, fn {_key, transformer}, acc ->
      LiveTable.Transformer.apply(acc, transformer)
    end)
  end
end
