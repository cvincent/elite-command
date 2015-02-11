class ActionDispatch::Session::AbstractStore
  alias_method :old_stale_session_check!, :stale_session_check!

  def stale_session_check!(&block)
    old_stale_session_check!(&block)
  rescue ActionDispatch::Session::SessionRestoreError
  end
end
