require 'resolv'
require 'socket'
require 'pp'

SRV = Struct.new(
    :priority,
    :weight,
    :port,
    :target
) do
  def available?
    begin
        sock = TCPSocket.open(target, port)
      true
    rescue SocketError, SystemCallError
      false
    ensure
      sock.close rescue nil
    end
  end
end

def resolve_srv(host)
  res = []
  adders = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::SRV)
  adders.each do |addr|
    srv = SRV.new(addr.priority, addr.weight, addr.port, addr.target.to_s)
    res.push(srv)
  end
  res
end

def pick_host(srv_list)
  if srv_list.empty?
    return srv_list
  end

  srv_list.sort_by!(&:priority).chunk(&:priority).sort.each do |_, list|
    sum = list.inject(0) { |sum, srv| sum + srv.weight}
    while sum > 0 && list.count > 1 do
      s = 0
      select = Integer(rand(sum))
      list.each_with_index do |srv, index|
        s += srv.weight
        if s > select
          if index > 0
            list[0], list[index] = list[index], list[0]
          end
          break
        end
      end
      sum -= list[0].weight
    end
    list
  end
  srv_list
end

@host = 'bootjp.me'
srv_service_name = 'fluentd'
transport = 'tcp'
host = "_#{srv_service_name}._#{transport}.#{@host}"

d = resolve_srv(host)
d = pick_host(d)

d.select! do |s|
  s.available?
end
pp d