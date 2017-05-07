;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals
[
 intersections
 roads
 vertical-roads
 horizontal-roads
 blocks
 gridx
 gridy
 beta
 pvalue
 work-travel
 time-interval
 num-travelling
 sender-list
 packet-list
 current-route-entry
 is-route?
 num-route-errors
 num-packets-transmitted
 num-routes-created
 destination-unreachable
 total-hops
 max-routes
 can-tick
 new-packet-list
 one-day
 num-days
 total-locations
 avg-num-neighbors
]

breed [workers worker]
breed [non-workers non-worker]

breed [workplaces workplace]
breed [houses house]
breed [locations location]

breed [route-tables route-table]

route-tables-own [src dest found-dest? node-list]

workers-own [direction has-destination? destX destY on-road? destination tried-to-move? moved-last? at-work? home-base work-time home-time work-base num-routes flooded? came-from num-locations]
non-workers-own [direction has-destination? destX destY on-road? destination tried-to-move? moved-last? home-base num-routes flooded? came-from num-locations]

houses-own [num-occupants]

turtles-own [prob-dist]
patches-own [has-place]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ask patches [ set pcolor gray ]
  set num-packets-transmitted 1
  set num-routes-created 1
  set num-days 1
  set total-locations 1
  set one-day false

  set-default-shape workers "person business"
  set-default-shape non-workers "person"

  set gridx 8
  set gridy 8

  set beta -1.59

  ;;array of probabilities determining if agents will move
  set pvalue [0.0058 0.0037 0.0023 0.0015 0.0011 0.0008 0.0006 0.0005 0.0005 0.0005 0.0007 0.0010 0.0016 0.0031 0.0066 0.0119 0.0165 0.0201 0.0240 0.0250 0.0275 0.0284 0.0295 0.0313 0.0353 0.0345 0.0313 0.0292 0.0277 0.0274 0.0290 0.0302 0.0329 0.0355 0.0409 0.0443 0.0458 0.0445 0.0422 0.0384 0.0340 0.0324 0.0281 0.0248 0.0224 0.0205 0.0148 0.0096]
  ;;array of probabilities determining when workers go to work
  set work-travel [0.003962461 0.003962461 0.003962461 0.003962461 0.003962461 0.003962461 0.003962461 0.003962461 0.003962461 0.003962461 0.035453597 0.047966632 0.085505735 0.102189781 0.147028154 0.133472367 0.109489051 0.056308655 0.031282586 0.031282586 0.014077164 0.014077164 0.006777894 0.006777894 0.008733055 0.008733055 0.008733055 0.008733055 0.008733055 0.008733055 0.008733055 0.008733055 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356 0.004301356]

  set vertical-roads patches with
    [(floor((pxcor + max-pxcor - floor(gridx - 1)) mod gridx) = 0) ] ;;vertical roads

  set horizontal-roads patches with
   [ (floor((pycor + max-pycor) mod gridy) = 0)] ;;horizontal rows

  set roads patches with
  [(floor((pxcor + max-pxcor - floor(gridx - 1)) mod gridx) = 0) or
    (floor((pycor + max-pycor) mod gridy) = 0)]

  set intersections roads with
    [(floor((pxcor + max-pxcor - floor(gridx - 1)) mod gridx) = 0) and
    (floor((pycor + max-pycor) mod gridy) = 0)]

  ask roads [ set pcolor white ]

  set blocks patches with
  [ floor(pxcor) mod gridx = (gridx / 2) and floor(pycor) mod gridy = 0 ]

  ask blocks
  [
   ;;set pcolor yellow
   set has-place false
  ]

  set-default-shape houses "house two story"
  create-houses num-houses
  [
    set color orange
    set size gridx / 2 ;; easier to see
    set num-occupants 0
    place-position
  ]

  set-default-shape workplaces "factory"
  create-workplaces num-workplaces
  [
    set color blue
    set size gridx / 2 ;; easier to see
    place-position
  ]

  set-default-shape locations "building store"
  create-locations num-stores
  [
    set color yellow
    set size gridx / 2 ;; easier to see
    place-position
  ]

  create-workers num-workers
  [
    set color blue
    set size 1.5  ;; easier to see
;;    set label-color black
;;    set label who
;;    setxy random-xcor random-ycor
    let my-house min-one-of houses [num-occupants]
    move-to my-house
    ask my-house [ set num-occupants num-occupants + 1 ]
    set home-base my-house
    determine-work-destination
    set has-destination? false
    set tried-to-move? false
    set moved-last? false
    set on-road? false
    set at-work? false
    set num-routes 0
    set flooded? false
    set num-locations 1
    determine-work-schedule
;;    pen-down
;;    set pen-size 3
  ]

  create-non-workers num-non-workers
  [
    set color red
;;    set label who
    set size 1.5  ;; easier to see
    ;;set label-color blue - 2
;;    setxy random-xcor random-ycor
    let my-house min-one-of houses [num-occupants]
    move-to my-house
    ask my-house [ set num-occupants num-occupants + 1 ]
    set home-base my-house
    set has-destination? false
    set tried-to-move? false
    set moved-last? false
    set on-road? false
    set num-routes 0
    set num-locations 1
    set flooded? false
;;    pen-down
;;    set pen-size 3
  ]

  set can-tick true
  reset-ticks

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go

  if can-tick
  [ad-hoc-network ]

  set can-tick true

  ask workers
  [
    travel true
    set can-tick can-tick and not has-destination?
  ]

  ask non-workers
  [
    travel false
    set can-tick can-tick and not has-destination?
  ]

  ask route-tables [ if found-dest? [ transmit-data ] ]

  let total-neighbors 0
  ask (turtle-set workers non-workers)
  [ set total-neighbors total-neighbors + count (turtle-set workers non-workers) in-radius transmission-range ]
  set avg-num-neighbors total-neighbors / (num-workers + num-non-workers)

  ;;kill people  if count people <= 2 [stop]
  ask max-one-of (turtle-set workers non-workers) [ num-routes ] [set max-routes num-routes]

  if can-tick
  [
    set num-days num-days + 1
    ask workers
    [ set tried-to-move? false ]

    ask non-workers
    [ set tried-to-move? false ]

    ifelse time-interval < 47
    [ set time-interval time-interval + 1 ]
    [
      set time-interval 0
      ask workers
      [
        determine-work-schedule
      ]
      ask (turtle-set workers non-workers)
      [
       set num-routes 0
       set num-locations 0
      ]
      if one-day [stop]
    ]
;;    set total-locations 1
    tick
    set num-travelling 0
    set destination-unreachable 0
    set total-hops 0
    set num-routes-created 1
    set num-route-errors 0
    set num-packets-transmitted 1
  ]


end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;determines how and when calling agent will travel
to travel [is-worker?]

  if not tried-to-move?
  [
    if is-worker?
    [
      if time-interval = work-time ;;and not at-work?
      [
        set total-locations total-locations + 1
        set num-locations num-locations + 1
        set num-travelling num-travelling + 1 ;;another person is moving
        set at-work? true
        find-best-road
        choose-destination work-base
        set tried-to-move? true
        set moved-last? false
      ]
      if time-interval = home-time
      [
        set num-travelling num-travelling + 1 ;;another person is moving
        set at-work? false
        find-best-road
        choose-destination home-base
        set tried-to-move? true
        set moved-last? false
      ]

    ]
  ]
  if not tried-to-move?
  [
    let probOfTravel random-float 1
    let multiplier 1
    if moved-last?
    [ set multiplier 10 ] ;;if ther person went 'out' last time they are 10 times more likely to go 'out' again

    ifelse ((probOfTravel < (item time-interval pvalue) * multiplier) or has-destination? ) ;;and not tried-to-move? ;; if probability is satisfied go out otherwise stay home or go back home
    [
      set total-locations total-locations + 1
      set num-locations num-locations + 1
      set num-travelling num-travelling + 1 ;;another person is moving
      set tried-to-move? true
      set moved-last? true
      find-best-road
      if not has-destination?
      [ determine-other-destination ]
    ]
    [
      if moved-last?
      [
        set num-travelling num-travelling + 1 ;;another person is moving
        find-best-road
        ifelse is-worker?
        [
          ifelse at-work?
          [ choose-destination work-base ]
          [ choose-destination home-base ]
        ]
        [choose-destination home-base]
      ]
      set tried-to-move? true
      set moved-last? false
    ]
 ]

  if has-destination? and tried-to-move?
  [
    find-best-road
    if on-road?
    [ travel-to-destination ]
    fd 1

    check-reached-destination
  ]


end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;sets position of places in an unoccupied block
to place-position

  let xpos 0
  let ypos 0

  ask one-of blocks with [ has-place = false ]
    [
      set has-place true
      set xpos pxcor
      set ypos pycor
    ]
    setxy xpos ypos

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;chooses a destination based n a power law distribution (r^-beta)
to determine-work-destination
  let d destination
  let probSum 0
  ask workplaces
  [
    if (self != d) ;;omit the current location
    [set probSum distance myself ^ beta + probSum] ;;calculate probability of moving to this location (r^-beta)
  ]

  let multiplier 1 / probSum ;; calculate multiplier such that the sum of the probabilities is 1

  ask workplaces
  [
    ifelse (self != d)
    [set prob-dist multiplier * ( distance myself ^ beta )] ;;set probability values for each destination
    [set prob-dist 0] ;;set the probability of the current location to be 0
  ]

  let power random-float 1 ;;get a random number between 0 and 1
  let total 0

  let done? false
  ask workplaces
  [
    ifelse done?
    [ stop ] ;;stop ask procedure
    [ set total total + prob-dist ] ;;accumulate probabilities
    if total >= power ;;if the current sum of probabilities is less than the power choose this as destination
    [
      set d self
      set done? true
    ]
  ]

  set work-base d

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;chooses a destination based n a power law distribution (r^-beta)
to determine-other-destination

  let d destination
  let probSum 0
  ask locations
  [
    if (self != d) ;;omit the current location
    [set probSum distance myself ^ beta + probSum] ;;calculate probability of moving to this location (r^-beta)
  ]

  let multiplier 1 / probSum ;; calculate multiplier such that the sum of the probabilities is 1

  ask locations
  [
    ifelse (self != d)
    [set prob-dist multiplier * ( distance myself ^ beta )] ;;set probability values for each destination
    [set prob-dist 0] ;;set the probability of the current location to be 0
  ]

  let power random-float 1 ;;get a random number between 0 and 1
  let total 0

  let done? false
  ask locations
  [
    ifelse done?
    [ stop ] ;;stop ask procedure
    [ set total total + prob-dist ] ;;accumulate probabilities
    if total >= power ;;if the current sum of probabilities is less than the power choose this as destination
    [
      set d self
      set done? true
    ]
  ]

  choose-destination d;;lx ly ;;set the person's destination

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;checks to see if calling agent has reached their destination
to check-reached-destination

  set has-destination? (abs ( destX - xcor ) > 1) and (abs (destY - ycor ) > 1)

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;sets the destination for the calling agent
to choose-destination [ d ] ;; turtle procedure
  let lx 0
  let ly 0
  ask d
  [
   set lx xcor
   set ly ycor
  ]
  set direction towardsxy lx ly ;;atan ( lx - xcor )  ( ly - ycor )
  set destX lx
  set destY ly
  set destination d
  set has-destination? true
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;finds closest road and sets direction attribute to face this road
to find-best-road ;;turtle procedure

  set on-road? (member? patch-here intersections) ;;if agent is on the road

;;  if on-road? [ stop ] ;;if already on a road, stop this procedure

  if not on-road? and not has-destination?
  [ set heading towards min-one-of intersections [ distance myself ] ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;travels along the roads
to travel-to-destination

 if member? patch-here intersections ;;makes decisions at intersection to go north/south or east/west
 [
   ifelse ( abs (ycor - desty) > abs (xcor - destx) )
   [ set direction ifelse-value (ycor < desty) [0] [180] ]
   [ set direction ifelse-value (xcor < destx) [90] [270] ]
 ]

 set heading direction

;; move-to-location

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;called by worker, determines work start time and end time
to determine-work-schedule
  let work-prob random-float 1 ;;get a random number between 0 and 1
  let total 0
  let prob-index 0
  set home-time 48
;;  while [home-time >= 48 or home-time = work-time] ;;ensure that workers go home before the day is over and they are at work for at least one interval
;;  [
    while [total < work-prob] ;;loop until the total is greater than the work probability
    [
      set total total + item prob-index work-travel ;;sum the work probability
      set prob-index prob-index + 1
    ]
    set work-time prob-index ;;set index of work time

    let work-duration round (100 * (random-normal 5 1.21) / 30)

    set home-time work-time + work-duration
;;  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;creates route betwwen random src and dest
to ad-hoc-network
  clear-links
  let d 0
  ask (turtle-set workers non-workers) [ set num-routes 0 ]
  ask route-tables [die]
  create-route-tables num-new-routes;;repeat num-new-routes
  [
    ht
    set node-list []
    set src one-of (turtle-set workers non-workers)
    ask src
    [
;;      set color green
      set d one-of other (turtle-set workers non-workers)
    ]
    set dest d
;;    ask dest [set color yellow]
    bfs-search src dest
    ifelse found-dest?
    [
      set num-routes-created num-routes-created + 1
      let ph d
      set node-list fput ph node-list
      while [ ph != src ]
      [
        ask ph
        [
          create-link-from came-from
          [set color yellow]
          set num-routes num-routes + 1
          set ph came-from
        ]
        set node-list fput ph node-list
      ]
      ask src [set num-routes num-routes + 1 ]
    ]
    [ set destination-unreachable destination-unreachable + 1 die ]
    set total-hops total-hops + (length node-list)
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;finds shortest route between src and dest
to bfs-search [ s d ]
  let openSet []
  let r-table self
  let current 0
;;  let tentative_gScore 0
  set found-dest? false
  set openSet lput s openSet

;;  let maxDist sqrt (world-width * world-width + world-height * world-height)

;;  ask s [set gScore 0 set fScore 1 ]

  ask (turtle-set workers non-workers) [set flooded? false ]

  while [ not empty? openSet ]
  [
    set current first openSet
    set openSet remove current openSet

    ask current
    [
;;      print current
;;      set tentative_gScore gScore + 1
      ask other (turtle-set workers non-workers) in-radius transmission-range
      [
        if self = d [set came-from current ask r-table [set found-dest? true] stop]
;;        set gScore tentative_gScore
;;        set fScore gscore + 1 - (distance current / maxDist)
        if not member? self openSet and not flooded?
        [
          set came-from current
          set openSet lput self openSet
        ]
        set flooded? true
      ]
    ]
    if found-dest? [stop]
;;    set openSet sort-by fScore openSet
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;transmits data from src to destination (route-table routine)
;;main purpose is to record route failures
to transmit-data
  set num-packets-transmitted num-packets-transmitted + 1
  let prev src
  let done false
  foreach node-list
  [
    ifelse ?1 != nobody
    [
      ask ?1 [ if num-routes > route-capacity [ die ] ] ;;too much traffic forces route to drop
      if prev != nobody and ?1 != nobody
      [
        if ?1 != prev
        [
          ask prev
          [
            if distance ?1 > transmission-range
            [
              if not done
              [ set num-route-errors num-route-errors + 1 ]
              ask out-link-to ?1 [hide-link]
              set done true
            ]
          ]
        ]
      ]
    ]
    [if not done [set num-route-errors num-route-errors + 1 set done true]]
    set prev ?1
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
212
10
1431
756
46
27
13.0
1
10
1
1
1
0
0
0
1
-46
46
-27
27
0
0
1
ticks
30.0

BUTTON
14
28
81
69
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
104
78
137
go
set one-day false\ngo
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
88
104
192
137
go one day
set one-day true\ngo
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
179
183
212
num-houses
num-houses
1
84 - num-workplaces - num-stores
26
1
1
NIL
HORIZONTAL

SLIDER
13
223
185
256
num-workplaces
num-workplaces
1
84 - num-houses - num-stores
28
1
1
NIL
HORIZONTAL

SLIDER
13
273
185
306
num-stores
num-stores
1
84 - num-workplaces - num-houses
28
1
1
NIL
HORIZONTAL

SLIDER
14
361
186
394
num-workers
num-workers
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
14
408
186
441
num-non-workers
num-non-workers
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
17
506
189
539
num-new-routes
num-new-routes
0
100
25
1
1
NIL
HORIZONTAL

PLOT
1443
12
1722
249
Route Failures
ticks
% Failures
0.0
48.0
0.0
100.0
true
false
"" ""
PENS
"% Failures" 1.0 0 -16777216 true "" "plot 100 * num-route-errors / num-packets-transmitted"
"% Moving" 1.0 0 -7500403 true "" "plot 100 * num-travelling / (num-workers + num-non-workers)"

SLIDER
15
553
195
586
transmission-range
transmission-range
0
100
10
1
1
NIL
HORIZONTAL

PLOT
1442
278
1722
509
Destinations Unreachable
ticks
% Unreachable
0.0
48.0
0.0
100.0
true
false
"" ""
PENS
"% Unreachable" 1.0 0 -16777216 true "" "plot 100 * destination-unreachable / num-new-routes"
"% Moving" 1.0 0 -7500403 true "" "plot 100 * num-travelling / (num-workers + num-non-workers)"

PLOT
1743
10
1973
248
Number of Locations Visited
Number of Locations
Number of People
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [num-locations] of (turtle-set workers non-workers)"

SLIDER
17
600
189
633
route-capacity
route-capacity
1
num-new-routes
22
1
1
NIL
HORIZONTAL

MONITOR
1742
439
1842
492
Network Size
count (turtle-set workers non-workers)
17
1
13

BUTTON
106
32
191
65
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1735
535
1978
753
Hops Per Route
ticks
Hops Per Route
0.0
48.0
0.0
10.0
true
false
"" ""
PENS
"Hops Per Route" 1.0 0 -16777216 true "" "plot total-hops / num-routes-created"
"% Moving" 1.0 0 -7500403 true "" "plot 100 * num-travelling / (num-workers + num-non-workers)"

PLOT
1443
538
1715
752
Max Routes
ticks
Max % of Total Routes
0.0
48.0
0.0
100.0
true
false
"" ""
PENS
"Max Routes" 1.0 0 -16777216 true "" "plot 100 * max-routes / num-new-routes"
"% Moving" 1.0 0 -7500403 true "" "plot 100 * num-travelling / (num-workers + num-non-workers)"

MONITOR
1737
294
1948
347
Average Number of Neighbors
avg-num-neighbors
17
1
13

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Num people sweep" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * num-travelling / (num-workers + num-non-workers)</metric>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <metric>total-hops / num-routes-created</metric>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-workers" first="1" step="10" last="100"/>
    <steppedValueSet variable="num-non-workers" first="1" step="10" last="100"/>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="max people no drops" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * num-travelling / (num-workers + num-non-workers)</metric>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <metric>total-hops / num-routes-created</metric>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="11.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="workers sweep" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * num-travelling / (num-workers + num-non-workers)</metric>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <metric>total-hops / num-routes-created</metric>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-workers" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="non-workers sweep" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * num-travelling / (num-workers + num-non-workers)</metric>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <metric>total-hops / num-routes-created</metric>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-non-workers" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="location sweep" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-houses" first="3" step="1" last="28"/>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="routing parameters" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <exitCondition>count (turtle-set workers non-workers) &lt; 2</exitCondition>
    <metric>100 * num-travelling / (num-workers + num-non-workers)</metric>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <metric>total-hops / num-routes-created</metric>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="route-capacity" first="2" step="5" last="22"/>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="transmission-range" first="5" step="10" last="55"/>
    <steppedValueSet variable="num-new-routes" first="1" step="10" last="51"/>
  </experiment>
  <experiment name="worker micro validation" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>total-locations</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="non-worker micro validation" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>total-locations</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="location sweep unreachable" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-houses" first="3" step="1" last="28"/>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="location sweep num hops" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>total-hops / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-houses" first="3" step="1" last="28"/>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="max people no drops reset to 0" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * num-travelling / (num-workers + num-non-workers)</metric>
    <metric>100 * num-route-errors / num-packets-transmitted</metric>
    <metric>total-hops / num-routes-created</metric>
    <metric>100 * destination-unreachable / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="11.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="non-workers sweep hops" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>total-hops / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-non-workers" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="non-workers sweep Max routes" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * max-routes / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-non-workers" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="workers sweep Max routes" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>100 * max-routes / num-routes-created</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-workers" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="workers sweep neighbors" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>set one-day true
go</go>
    <metric>avg-num-neighbors</metric>
    <enumeratedValueSet variable="num-stores">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-non-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-capacity">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-houses">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="28"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-workers" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="transmission-range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-new-routes">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
