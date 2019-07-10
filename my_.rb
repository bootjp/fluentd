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
  # fixme more think. sort srv embedded?
  # def <=> (b)
  #   :priority < b.priority || (:priority == b.priority && :weight < b.weight)
  # end
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
  srv_list.sort_by!(&:weight)
  srv_list.sort_by!(&:priority)

  until (srv_list.size - 1) < current do
    if srv_list[last]['priority'] != srv_list[current]['priority']
      ret.push weight_by_shuffle srv_list[last...current]
      last = current
    end
    current += 1
  end
  ret.push weight_by_shuffle srv_list[last...current]
  ret
end

def weight_by_shuffle(srv_list)
  if srv_list.nil? || srv_list.empty?
    return []
  end

  # Compute the sum of the weights of those RRs, and with each RR
  # associate the running sum in the selected order
  sum = srv_list.inject(0) { |sum, srv| sum + srv.weight}

  # Then choose a
  # uniform random number between 0 and the sum computed
  # (inclusive), and select the RR whose running sum value is the
  # first in the selected order which is greater than or equal to
  # the random number selected.

  until srv_list.empty?
    # Then choose a uniform random number between 0 and the sum computed (inclusive),
    selector = Integer(rand(sum))
    running_sum = 0

    # todo 順序付けされていないSRV RRがなくなるまで、順序付けプロセスを続けます。 このプロセスは優先度ごとに繰り返されます。
    srv_list.each_index do |index|
      running_sum += srv_list[index].weight
      # and select the RR whose running sum value is the first in the selected order which is greater than or equal to the random number selected.
      if running_sum > selector
        if index > 0
          # The target host specified in the selected SRV RR is the next one to be contacted by the client.
          srv_list[0] = srv_list[index]
          srv_list[index] = srv_list[0]
        end
        break
      end
    end
  end
  srv_list
end

ret = srv_list_sort_priority_weight(
    [
      SRV.new(0, 100, 22424, "aas"),
      SRV.new(2, 20, 22424, "cc"),
      SRV.new(2, 10, 22424, "aa"),
      SRV.new(4, 100, 22424, "localhost"),
      SRV.new(2, 100, 22424, "bnbb"),
    ]
)
#
#
# ret = weight_by_shuffle(
#     [
#       # SRV.new(0, 100, 22424, "localhost"),
#         SRV.new(2, 30, 22424, "vvvv"),
#       SRV.new(2, 60, 22424, "localhost"),
#       SRV.new(2, 40, 22424, "localhost"),
#         # SRV.new(2, 30, 22424, "vvvv"),
#       # SRV.new(2, 100, 22424, "localhost"),
#     ]
# =begin
#     ].shuffle!
# =end
# )
# #
pp "--"

pp ret