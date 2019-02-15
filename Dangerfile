# frozen_string_literal: true

fail('Please rebase to get rid of the merge commits in this PR') if git.commits.any? { |c| c.message =~ /^Merge branch/ }

updated_files = git.modified_files + git.added_files
changed_files = updated_files + git.deleted_files
has_app_changes = !changed_files.grep(/lib/).empty?
has_test_changes = !changed_files.grep(/spec/).empty?

warn('Tests were not updated', sticky: false) if has_app_changes && !has_test_changes

rubocop.lint(
  files: updated_files,
  force_exclusion: true,
  inline_comment: true,
  report_danger: true
)
