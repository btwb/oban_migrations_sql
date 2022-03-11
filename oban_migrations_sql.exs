#!/usr/bin/env elixir

defmodule VersionTag do
  def to_string(version) when is_integer(version) do
    version
    |> Kernel.to_string()
    |> String.pad_leading(2, "0")
    |> then(&("v" <> &1))
  end

  def parse("v" <> tag) do
    {version, ""} = Integer.parse(tag)
    version
  end
end

defmodule ObanMigrationsGenerator do
  defp templates_path, do: "#{__DIR__}/migrations"

  def main() do
    {options, _} =
      OptionParser.parse!(System.argv(),
        strict: [
          prefix: :string,
          out: :string,
          from: :integer,
          to: :integer,
          create_schema: :boolean
        ]
      )

    options =
      Keyword.validate!(options, [
        prefix: "public",
        out: "./out",
        from: Enum.min(known_version_range()),
        to: Enum.max(known_version_range()),
        create_schema: true
      ])

    prefix = Keyword.fetch!(options, :prefix)
    migrations_path = Keyword.fetch!(options, :out)

    version_range =
      Range.new(
        Keyword.fetch!(options, :from),
        Keyword.fetch!(options, :to)
      )

    assigns = [
      prefix: prefix,
      create_schema: Keyword.fetch!(options, :create_schema)
    ]

    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    from_version_tag = Enum.min(version_range) |> VersionTag.to_string()
    to_version_tag = Enum.max(version_range) |> VersionTag.to_string()
    migration_name = "#{timestamp}_#{prefix}_oban_#{from_version_tag}_to_#{to_version_tag}"

    sqls =
      for migration_direction <- [:up, :down], into: %{} do
        sql =
          version_range
          |> then(
            &if migration_direction == :down do
              Enum.reverse(&1)
            else
              &1
            end
          )
          |> Enum.map(&build_migration!(&1, migration_direction, assigns))
          |> Enum.concat([
            record_version(version_range, migration_direction, prefix)
          ])
          |> Enum.map_join("\n\n", &String.trim/1)
          |> String.trim()
          |> Kernel.<>("\n")

        {migration_direction, sql}
      end

    output_path = Path.join(migrations_path, migration_name)
    File.mkdir_p!(output_path)

    for {direction, sql} <- sqls do
      Path.join(output_path, "#{direction}.sql")
      |> File.write!(sql)
    end
  end

  defp known_version_range() do
    Path.join(templates_path(), "v*")
    |> Path.wildcard()
    |> Enum.map(&Path.basename/1)
    |> Enum.map(&VersionTag.parse/1)
  end

  defp build_migration!(version, migration_direction, assigns) do
    sql =
      migration_template_path(version, migration_direction)
      |> eval_template!(assigns)

    """
    -- #{VersionTag.to_string(version)}
    #{sql}
    """
  end

  defp migration_template_path(version, direction) do
    Path.join([templates_path(), VersionTag.to_string(version), "#{direction}.sql.eex"])
  end

  defp eval_template!(path, assigns) do
    EEx.eval_file(path, assigns: assigns)
  end

  defp record_version(version_range, :up, prefix) do
    to_version = Enum.max(version_range)
    record_version_sql(to_version, prefix)
  end

  defp record_version(version_range, :down, prefix) do
    from_version = Enum.min(version_range)
    record_version_sql(from_version - 1, prefix)
  end

  defp record_version_sql(0, _) do
    ""
  end

  defp record_version_sql(version, prefix) do
    """
    -- Save latest Oban database version for later introspection.
    COMMENT ON TABLE #{prefix}.oban_jobs IS '#{version}'
    """
  end
end

ObanMigrationsGenerator.main()
