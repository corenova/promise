#
# Author: Peter K. Lee (peter@corenova.com)
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#

require('yang-js').register()
require './nfv-infrastructure'

module.exports = require('../schema/opnfv-promise.yang').bind {

  '/promise/capacity/total': ->
    combine = (a, b) ->
      for k, v of b.capacity when v?
        a[k] ?= 0
        a[k] += v
      return a
    (@get '/promise/pools')
    .filter (entry) -> entry.active is true
    .reduce combine, {}

  '/promise/capacity/reserved': ->
    combine = (a, b) ->
      for k, v of b.remaining when v?
        a[k] ?= 0
        a[k] += v
      return a
    (@get '/promise/reservations')
    .filter (entry) -> entry.active is true
    .reduce combine, {}

  '/promise/capacity/usage': ->
    combine = (a, b) ->
      for k, v of b.capacity when v?
        a[k] ?= 0
        a[k] += v
      return a
    (@get '/promise/allocations')
    .filter (entry) -> entry.active is true
    .reduce combine, {}

  '/promise/capacity/available': ->
    total    = @get '../total'
    reserved = @get '../reserved'
    usage    = @get '../usage'
    for k, v of total when v?
      total[k] -= reserved[k] if reserved[k]?
      total[k] -= usage[k] if usage[k]?
    total

  'complex-type:ResourceCollection':
    start:  -> (new Date).toJSON()
    active: ->
      now = new Date
      start = new Date (@get 'start')
      end = switch
      when (@get 'end')? then new Date (@get 'end')
      else now
        (@get 'enabled') and (start <= now <= end)

  # Intent Processor bindings
  'rpc:create-reservation': require './rpc/create-reservation'
  'rpc:query-reservation':  require './rpc/query-reservation'
  'rpc:update-reservation': require './rpc/update-reservation'
  'rpc:cancel-reservation': require './rpc/cancel-reservation'
  'rpc:query-capacity':     require './rpc/query-capacity'
  'rpc:increase-capacity':  require './rpc/increase-capacity'
  'rpc:decrease-capacity':  require './rpc/decrease-capacity'

}
