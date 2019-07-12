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

## TODO ADD TEST
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
    if srv_list[last].priority != srv_list[current].priority
      ret.push weight_by_shuffle srv_list[last...current]
      last = current
    end
    current += 1
  end
  ret.push weight_by_shuffle srv_list[last...current]
  ret
end

## TODO ADD TEST
def weight_shuffle(srv_list)
  if srv_list.nil? || srv_list.empty?
    return []
  end

  # To select a target to be contacted next, arrange all SRV RRs
  #  (that have not been ordered yet) in any order, except that all
  # those with weight 0 are placed at the beginning of the list.
  shuffle_start = nil
  srv_list.sort_by!(&:weight)
  srv_list.each_index do |index|
    if srv_list[index].weight != 0
      if shuffle_start.nil?
        shuffle_start = index
      end
      if !shuffle_start.nil? && srv_list[index].weight != 0
        shuffle_end = index
        target = srv_list.dup
        srv_list[shuffle_start..shuffle_end] = target[shuffle_start..shuffle_end].shuffle!
      end
    end
  end

  srv_list
end

## TODO ADD TEST
def weight_by_shuffle(srv_list)
  if srv_list.nil? || srv_list.empty?
    return []
  end

  # Compute the sum of the weights of those RRs, and with each RR
  # associate the running sum in the selected order
  sum = srv_list.inject(0) { |sum, srv| sum + srv.weight}

  srv_list = weight_shuffle(srv_list)
  ret = []
  # Then choose a uniform random number between 0 and the sum computed (inclusive),
  # and select the RR whose running sum value is the first in the selected order which is greater than or equal to the random number selected.
  until sum <= 0 || srv_list.empty?
    selector = Integer(rand(sum))
    running_sum = 0

    srv_list.each_index do |index|
      running_sum += srv_list[index].weight
      if running_sum > selector
        ret.push srv_list[index]
        sum -= srv_list[index].weight
        srv_list.delete_at index
        break
      end
    end
  end
  ret
end
