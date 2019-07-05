require "pp"

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

def srv_list_sort_priority_weight(srv_list)
  if srv_list.nil? || srv_list.empty?
    return []
  end

  # If the reply is NOERROR, ANCOUNT>0 and there is at least one
  # SRV RR which specifies the requested Service and Protocol in
  # the reply
  sum = srv_list.inject(0) { |sum, srv| sum + srv.weight}
  if sum == 0 || srv_list.count <= 1
    return srv_list
  end

  # Sort the list by priority (lowest number first)

  last = 0
  current = 1

  ret = []
  srv_list.sort_by!(&:priority)
  # pp srv_list
  until (srv_list.size - 1) < current do
    # pp last, current
    # pp srv_list[last]['priority'] != srv_list[current]['priority']
    if srv_list[last]['priority'] != srv_list[current]['priority']
      ret.push weight_by_shuffle srv_list[last...current]
      # pp "---"
      last = current
    end
    current += 1
  end
  ret.push weight_by_shuffle srv_list[last...current] # weight sort)
  # ret =

  ret
end

def weight_by_shuffle(srv_list)
  if srv_list.nil? || srv_list.empty?
    return []
  end

  # if srv_list.length == 1
  #   return srv_list
  # end

  # Compute the sum of the weights of those RRs, and with each RR
  # associate the running sum in the selected order
  sum = srv_list.inject(0) { |sum, srv| sum + srv.weight}

  # Then choose a
  # uniform random number between 0 and the sum computed
  # (inclusive), and select the RR whose running sum value is the
  # first in the selected order which is greater than or equal to
  # the random number selected.
  pp srv_list

  while sum > 0 && srv_list.length > 1
    pp "loop"
    selector = Integer(rand(sum))
    selected_sum = 0
    srv_list.each.with_index do |srv, index|
      selected_sum += srv.weight
      if selected_sum > selector
        if index > 0
          pp "index",  index
          srv_list[0], srv_list[index] = srv_list[index], srv_list[0]
        end
      end
    end
    pp srv_list
    # fixme
    sum -= srv_list[0].weight
    srv_list = srv_list[0..-1]
  end

  srv_list
end

ret = srv_list_sort_priority_weight(
    [
      SRV.new(0, 100, 22424, "localhost"),
      SRV.new(2, 10, 22424, "localhost"),
      SRV.new(4, 100, 22424, "localhost"),
      SRV.new(2, 100, 22424, "localhost"),
    ]
)
pp "--"

pp ret