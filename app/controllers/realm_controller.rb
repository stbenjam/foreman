class RealmController < ApplicationController
  before_filter :find_proxy

  def index
    # expire cache if forced
    Rails.cache.delete("realm_#{@proxy.id}") if params[:expire_cache] == "true"

    begin
      certs = if params[:state].blank?
                SmartProxies::Realm.find_by_state(@proxy, "valid") + SmartProxies::Realm.find_by_state(@proxy, "pending")
              elsif params[:state] == "all"
                SmartProxies::Realm.all @proxy
              else
                SmartProxies::Realm.find_by_state @proxy, params[:state]
              end
    rescue => e
      certs = []
      error e
      redirect_to :back and return
    end
    respond_to do |format|
      format.html do
        begin
          @certificates = certs.sort.paginate :page => params[:page], :per_page => params[:per_page] || 20
        rescue => e
          error e
        end
      end
      format.json { render :json => certificates }
    end
  end

  def update
    cert = SmartProxies::Realm.find(@proxy, params[:id])
    if cert.sign
      process_success({ :success_redirect => smart_proxy_realm_index_path(@proxy, :state => params[:state]), :object_name => cert.to_s })
    else
      process_error({ :redirect => smart_proxy_realm_index_path(@proxy) })
    end
  rescue
    process_error({ :redirect => smart_proxy_realm_index_path(@proxy) })
  end

  def destroy
    cert = SmartProxies::Realm.find(@proxy, params[:id])
    if cert.destroy
      process_success({ :success_redirect => smart_proxy_realm_index_path(@proxy, :state => params[:state]), :object_name => cert.to_s })
    else
      process_error({ :redirect => smart_proxy_realm_index_path(@proxy) })
    end
  end

  private

  def find_proxy
    @proxy = SmartProxy.find(params[:smart_proxy_id])
  end

end
