require 'resolv'
require 'socket'
require 'pp'

SRV = Struct.new(
    :priority,
    :weight,
    :port,
    :target,
    :available
)

def resolve_srv(host)
  adders = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::SRV)

  res = []
  adders.each do |addr|
    srv = SRV.new(addr.priority, addr.weight, addr.port, addr.target.to_s)
    res.push(srv)
  end
  res
end

def try_connect(host, port)
  begin
    sock = TCPSocket.open(host, port)
    true
  rescue StandardError
    false
  ensure
    sock.close rescue nil
  end
end

def pick_host(srv_list)
  srv_list.sort_by!(&:priority).chunk(&:priority).sort.each do |priority, srv_list|
    sum = srv_list.inject(0) { |sum, srv| sum + srv.weight}

    if srv_list.empty?
      return srv_list
    end

    while sum > 0 do
      s = 0
      select = Integer(rand(sum))
      srv_list.each_with_index do |srv, index|
        s += srv.weight
        if s > select
          if index > 0
            srv_list[0], srv_list[index] = srv_list[index], srv_list[0]
          end
          break
        end
      end
      sum -= srv_list[0].weight
    end
    srv_list
  end
  srv_list
end

@host = 'bootjp.me'
srv_service_name = 'fluentd'
transport = 'tcp'
host = "_#{srv_service_name}._#{transport}.#{@host}"

d = resolve_srv(host)
