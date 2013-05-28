class JoinrealmController < ApplicationController
  before_filter :find_proxy, :setup_proxy

  def index
    begin
      realm_join = @api.realm_join
    rescue => e
      realm_join = []
      error e
    end
    respond_to do |format|
      format.html { @realm_join = realm_join.paginate :page => params[:page], :per_page => 20 }
      format.json {render :json => realm_join }
    end
  end

  def new
  end

  def create
    if @api.set_realm_join(params[:id])
      process_success({:success_redirect => smart_proxy_realm_index_path(@proxy), :object_name => 'puppet realm entry'})
    else
      process_error({:redirect => smart_proxy_realm_index_path(@proxy)})
    end
  end

  def destroy
    if @api.del_realm_join(params[:id])
      process_success({:success_redirect => smart_proxy_realm_index_path(@proxy), :object_name => 'puppet realm entry'})
    else
      process_error({:redirect => smart_proxy_realm_index_path(@proxy)})
    end
  end

  private

  def find_proxy
    @proxy = SmartProxy.find(params[:smart_proxy_id])
  end

  def setup_proxy
    @api = ProxyAPI::Realm.new({:url => @proxy.url})
  end
end
