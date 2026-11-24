-- NOTE: the sandbox run stopped before the protected script's own code started (finished).
-- What follows is Luraph's startup and anti-tamper code, not the script itself.
-- Luraph runtime function (from the VM object, not part of the script: not lifted).
-- LPH_ENCFUNC decrypts a function this way: (key, encrypted buffer, ...) -> function.
local function luraph_runtime1(...)
	error("Luraph runtime function, not devirtualized")
end

-- Luraph runtime function (from the VM object, not part of the script: not lifted).
-- LPH_ENCFUNC decrypts a function this way: (key, encrypted buffer, ...) -> function.
local function luraph_runtime2(...)
	error("Luraph runtime function, not devirtualized")
end

-- Luraph runtime function (from the VM object, not part of the script: not lifted).
-- LPH_ENCFUNC decrypts a function this way: (key, encrypted buffer, ...) -> function.
local function luraph_runtime3(...)
	error("Luraph runtime function, not devirtualized")
end

-- Luraph runtime function (from the VM object, not part of the script: not lifted).
-- LPH_ENCFUNC decrypts a function this way: (key, encrypted buffer, ...) -> function.
local function luraph_runtime4(...)
	error("Luraph runtime function, not devirtualized")
end

-- Luraph runtime function (from the VM object, not part of the script: not lifted).
-- LPH_ENCFUNC decrypts a function this way: (key, encrypted buffer, ...) -> function.
local function luraph_runtime5(...)
	error("Luraph runtime function, not devirtualized")
end

-- Luraph runtime function (from the VM object, not part of the script: not lifted).
-- LPH_ENCFUNC decrypts a function this way: (key, encrypted buffer, ...) -> function.
local function luraph_runtime6(...)
	error("Luraph runtime function, not devirtualized")
end

local fn
fn = nil
local v
v = nil
local v2 = nil
local v3 = nil
local v4 = nil
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = nil
local v10 = nil
local v11 = nil
local v12 = nil
local v13
v13 = nil
local v14 = nil
local v15 = nil
local v16 = nil
local v17 = nil
local v18 = nil
local v19
v19 = nil
local v20
v20 = nil
local v21 = nil
local v22 = nil
local v23 = nil
local v24 = nil
local v25
v25 = nil
local v26 = v13
local fn2
fn2 = v19
local fn3
fn3 = v20
local fn4
fn4 = v25
local v27
v27 = task
local cancel
cancel = v27.cancel
local spawn
spawn = v27.spawn
local defer
defer = v27.defer
local delay
delay = v27.delay
local wait
wait = v27.wait
local v28
v28 = Instance
local v29
v29 = Vector3
local v30
v30 = Vector2
local v31
v31 = CFrame
local v32
v32 = Random
local v33
v33 = identifyexecutor
local v34
v34 = islclosure
local v35
v35 = iscclosure
local v36
v36 = loadstring
local fn5, fn6

do
	local tbl = { 200, 110, 184, 74, 23, 203, 91, 192, 146, 212, 46, 172 }
	local n = 12
	local tbl2 = { 47, 113, 30, 189, 35, 65, 196, 139, 86, 163, 5, 36 }
	local n2 = 12
	local n3 = 9498
	local tbl3 = {}
	local n4 = 0

	fn5 = function(arg, arg2)
		n4 += 1
		tbl3[n4] = arg2 % 256
	end

	fn6 = function(arg, arg2)
		local tbl4 = { nil, 1, nil, arg2 + 0, 0 }

		while true do
			local v37 = tbl4[2]
			local v38 = tbl4[4]
			local n5 = tbl4[5] + v37
			local flag = v37 <= 0
			tbl4[5] = n5

			if n5 <= v38 then
				local n6 = arg % 256
				arg = (arg - n6) / 256
				n4 += 1
				tbl3[n4] = n6
			else
				break
			end
		end
	end

	local function fn7()
		error("devirt: symbolic value store into proto array (at 26:1264)")
	end

	local function fn8(arg, arg2, arg3)
		local v37 = nil
		local v38 = nil
		local v39, v40 = fn7(nil - 2073651994)
		local v41 = luraph_runtime6(nil, nil, table.pack(v10, v11, v8))()
		local tbl4 = { nil, -1, nil, 255, 1 }

		while true do
			local v42 = tbl4[5]
			local v43 = tbl4[4]
			local n5 = tbl4[2] + v42
			local flag = v42 <= 0
			tbl4[2] = n5

			if n5 <= v43 then
				v39[n5] = 0
			else
				break
			end
		end

		local n5 = buffer.len(v41) - 156 - 114
		bit32.bor("StarterPlayer", v37)
		error("devirt: symbolic value store into proto array (at 26:598)")
	end
end

local v37
v37 = assert(debug, "The debug library is required on Luau platforms. Please open a support ticket.")
local info
info = v37.info
local traceback
traceback = v37.traceback
local n
n = 473582754
local fn7

fn7 = function()
	local function fn8(arg, arg2, arg3, arg4, arg5, arg6)
		local n2 = 489466012
		local tbl = { 0, nil, 4, nil, 1 }
		local tbl2 = { arg2, arg3, arg4, arg6 }
		local v38, n3, n4, n5, n6, v39, v40, v41, writeu32, v42, v43, writei16, v44, v45

		while true do
			local v46 = tbl[5]
			local v47 = tbl[3]
			local n7 = tbl[1] + v46
			local flag = v46 <= 0
			local flag2 = not flag
			local flag3 = n7 >= v47
			local flag4 = n7 <= v47
			local v48, tbl3, v49, v50, n8, flag5, v51, v52, n9, v53, v54, n10, v55, n11, v56, n12, n13, v57, v58, v59, n14, v60, v61, v62, n15, n16, n17, v63, n18, v64, v65, v66, v67, v68, n19, v69, n20, v70, v71, v72, n21, v73, v74, n22, v75, n23, n24, v76, v77, n25, n26, n27

			if flag then
				if flag2 then
					if flag3 then
						tbl[1] = n7

						if flag3 then
							v48 = tbl2[n7]
							tbl3 = { 1, 0, nil, tbl, #v48 + 0 }

							while true do
								v49 = tbl3[1]
								v50 = tbl3[5]
								n8 = tbl3[2] + v49
								flag5 = v49 <= 0
								tbl3[2] = n8

								if n8 <= v50 then
									v51 = n8
									v52 = bit32.lshift(bit32.band(n2, v51), 1)
									local v78 = table.pack(bit32.band(v51, 4294967295))
									local v79 = table.pack(bit32.band(v78[1], 65535))
									n9 = v52 + bit32.band(12155 * v79[1] + bit32.lshift(bit32.band(12155 * bit32.rshift(v78[1], 16) + 14506 * v79[1], 65535), 16), 4294967295)
									v53 = bit32.band(489466013, n2)
									local v80 = table.pack(bit32.band(n2, 4294967295))
									local v81 = table.pack(bit32.band(v53, 4294967295))
									local v82 = table.pack(bit32.band(v80[1], 65535))
									local v83 = table.pack(bit32.rshift(v80[1], 16))
									local v84 = table.pack(bit32.band(v81[1], 65535))
									local v85 = table.pack(bit32.band(bit32.band(v82[1] * v84[1] + bit32.lshift(bit32.band(v82[1] * bit32.rshift(v81[1], 16) + v83[1] * v84[1], 65535), 16), 4294967295), 4294967295))
									local v86 = table.pack(bit32.band(v85[1], 65535))
									v54 = bit32.band(60968 * v86[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v85[1], 16) + 52495 * v86[1], 65535), 16), 4294967295)
									local v87 = table.pack(bit32.band(n2, 4294967295))
									local v88 = table.pack(bit32.band(v87[1], 65535))
									n10 = n9 + v54 + bit32.band(48813 * v88[1] + bit32.lshift(bit32.band(48813 * bit32.rshift(v87[1], 16) + 37989 * v88[1], 65535), 16), 4294967295)
									v55 = bit32.band(bit32.bnot(n2), 1)
									local v89 = table.pack(bit32.band(n2, 4294967295))
									local v90 = table.pack(bit32.band(v55, 4294967295))
									local v91 = table.pack(bit32.band(v89[1], 65535))
									local v92 = table.pack(bit32.rshift(v89[1], 16))
									local v93 = table.pack(bit32.band(v90[1], 65535))
									local v94 = table.pack(bit32.band(bit32.band(v91[1] * v93[1] + bit32.lshift(bit32.band(v91[1] * bit32.rshift(v90[1], 16) + v92[1] * v93[1], 65535), 16), 4294967295), 4294967295))
									local v95 = table.pack(bit32.band(v94[1], 65535))
									n11 = 2508247598 + bit32.band(60968 * v95[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v94[1], 16) + 52495 * v95[1], 65535), 16), 4294967295)
									local v96 = table.pack(bit32.band(v53, 4294967295))
									local v97 = table.pack(bit32.band(v96[1], 65535))
									v56 = bit32.band(24310 * v97[1] + bit32.lshift(bit32.band(24310 * bit32.rshift(v96[1], 16) + 29012 * v97[1], 65535), 16), 4294967295)
									bit32.bor(n2, v52)
									bit32.bnot(v51)
									local v98 = table.pack(bit32.band(n2, 4294967295))
									local v99 = table.pack(bit32.band(v98[1], 65535))
									local v100 = table.pack(bit32.band(bit32.band(v99[1] * 22370 + bit32.lshift(bit32.band(v99[1] * 58067 + bit32.rshift(v98[1], 16) * 22370, 65535), 16), 4294967295), 4294967295))
									local v101 = table.pack(bit32.band(v100[1], 65535))
									n12 = n10 + n11 + v56 + bit32.band(60968 * v101[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v100[1], 16) + 52495 * v101[1], 65535), 16), 4294967295)
									local v102 = table.pack(bit32.band(n12, 4294967295))
									local v103 = table.pack(bit32.band(v102[1], 65535))
									n13 = 127928343 + bit32.band(23910 * v103[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v102[1], 16) + 20095 * v103[1], 65535), 16), 4294967295)
									local v104 = table.pack(bit32.band(bit32.bor(2147483648, n12), 4294967295))
									local v105 = table.pack(bit32.band(v104[1], 65535))
									v57 = bit32.band(41626 * v105[1] + bit32.lshift(bit32.band(41626 * bit32.rshift(v104[1], 16) + 45440 * v105[1], 65535), 16), 4294967295)
									v58 = bit32.bor(2147483647, n12)
									local v106 = table.pack(bit32.band(bit32.bnot(v58), 4294967295))
									local v107 = table.pack(bit32.band(v106[1], 65535))
									local v108 = table.pack(bit32.band(4422895639 - n13 + v57 + bit32.band(23910 * v107[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v106[1], 16) + 20095 * v107[1], 65535), 16), 4294967295), 4294967295))
									local v109 = table.pack(bit32.band(v108[1], 65535))
									v59 = bit32.band(33239 * v109[1] + bit32.lshift(bit32.band(33239 * bit32.rshift(v108[1], 16) + 55971 * v109[1], 65535), 16), 4294967295)
									local v110 = table.pack(bit32.band(n12, 4294967295))
									local v111 = table.pack(bit32.band(v110[1], 65535))
									n14 = 447350770 + bit32.band(18771 * v111[1] + bit32.lshift(bit32.band(18771 * bit32.rshift(v110[1], 16) + 20694 * v111[1], 65535), 16), 4294967295) + 2539006698 + 9346683268
									v60 = bit32.band(2147483647, n12)
									v61 = bit32.band(3849543541, v60)
									local v112 = table.pack(bit32.band(v61, 4294967295))
									local v113 = table.pack(bit32.band(v112[1], 65535))
									local v114 = table.pack(bit32.band(bit32.band(41098 * v113[1] + bit32.lshift(bit32.band(41098 * bit32.rshift(v112[1], 16) + 6796 * v113[1], 65535), 16), 4294967295), 4294967295))
									local v115 = table.pack(bit32.band(v114[1], 65535))
									v62 = bit32.band(21972 * v115[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v114[1], 16) + 11948 * v115[1], 65535), 16), 4294967295)
									bit32.band(n12, 2147483647)
									local v116 = table.pack(bit32.band(v61, 4294967295))
									local v117 = table.pack(bit32.band(v116[1], 65535))
									n15 = v62 + 0 + 3178001138 + bit32.band(2 * v117[1] + bit32.lshift(bit32.band(2 * bit32.rshift(v116[1], 16) + 0 * v117[1], 65535), 16), 4294967295)
									local v118 = table.pack(bit32.band(v61, 4294967295))
									local v119 = table.pack(bit32.band(v118[1], 65535))
									local v120 = table.pack(bit32.band(bit32.band(v119[1] * 65535 + bit32.lshift(bit32.band(v119[1] * 32767 + bit32.rshift(v118[1], 16) * 65535, 65535), 16), 4294967295), 4294967295))
									local v121 = table.pack(bit32.band(v120[1], 65535))
									n16 = 361090504 + bit32.band(43564 * v121[1] + bit32.lshift(bit32.band(43564 * bit32.rshift(v120[1], 16) + 53587 * v121[1], 65535), 16), 4294967295)
									local v122 = table.pack(bit32.band(v61, 4294967295))
									local v123 = table.pack(bit32.band(v122[1], 65535))
									local v124 = table.pack(bit32.band(bit32.band(v123[1] * 24437 + bit32.lshift(bit32.band(v123[1] * 25971 + bit32.rshift(v122[1], 16) * 24437, 65535), 16), 4294967295), 4294967295))
									local v125 = table.pack(bit32.band(v124[1], 65535))
									n17 = v59 + n14 + n15 + n16 + 3221896868 + 1450886216 + bit32.band(21972 * v125[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v124[1], 16) + 11948 * v125[1], 65535), 16), 4294967295)
									v48[v51] = bit32.bxor(v48[v51], 127928343)
									local v126 = table.pack(bit32.band(v51, 4294967295))
									local v127 = table.pack(bit32.band(v126[1], 65535))
									v63 = bit32.band(v127[1] * 22617 + bit32.lshift(bit32.band(v127[1] * 5106 + bit32.rshift(v126[1], 16) * 22617, 65535), 16), 4294967295)
									n18 = n2 + 555967646
									local v128 = table.pack(bit32.band(n18, 4294967295))
									local v129 = table.pack(bit32.band(v128[1], 65535))
									v64 = bit32.band(40380 * v129[1] + bit32.lshift(bit32.band(40380 * bit32.rshift(v128[1], 16) + 25636 * v129[1], 65535), 16), 4294967295)
									local v130 = table.pack(bit32.band(v63, 4294967295))
									local v131 = table.pack(bit32.band(v130[1], 65535))
									v65 = bit32.band(25156 * v131[1] + bit32.lshift(bit32.band(25156 * bit32.rshift(v130[1], 16) + 39899 * v131[1], 65535), 16), 4294967295)
									v66 = bit32.bor(445423754, v63)
									v67 = bit32.bnot(v66)
									local v132 = table.pack(bit32.band(v63, 4294967295))
									local v133 = table.pack(bit32.band(v67, 4294967295))
									local v134 = table.pack(bit32.band(v132[1], 65535))
									local v135 = table.pack(bit32.rshift(v132[1], 16))
									local v136 = table.pack(bit32.band(v133[1], 65535))
									local v137 = table.pack(bit32.band(bit32.band(v134[1] * v136[1] + bit32.lshift(bit32.band(v134[1] * bit32.rshift(v133[1], 16) + v135[1] * v136[1], 65535), 16), 4294967295), 4294967295))
									local v138 = table.pack(bit32.band(v137[1], 65535))
									v68 = v63
									n19 = v64 + v65 + bit32.band(16279 * v138[1] + bit32.lshift(bit32.band(16279 * bit32.rshift(v137[1], 16) + 40956 * v138[1], 65535), 16), 4294967295)
									v69 = bit32.band(n17, 445423754)
									local v139 = table.pack(bit32.band(bit32.band(bit32.bnot(n18), v68), 4294967295))
									local v140 = table.pack(bit32.band(v139[1], 65535))
									n20 = v69 + bit32.band(40381 * v140[1] + bit32.lshift(bit32.band(40381 * bit32.rshift(v139[1], 16) + 25636 * v140[1], 65535), 16), 4294967295)
									v70 = bit32.bnot(v68)
									v71 = bit32.band(v70, 3849543541)
									local v141 = table.pack(bit32.band(v68, 4294967295))
									local v142 = table.pack(bit32.band(v71, 4294967295))
									local v143 = table.pack(bit32.band(v141[1], 65535))
									local v144 = table.pack(bit32.rshift(v141[1], 16))
									local v145 = table.pack(bit32.band(v142[1], 65535))
									local v146 = table.pack(bit32.band(bit32.band(v143[1] * v145[1] + bit32.lshift(bit32.band(v143[1] * bit32.rshift(v142[1], 16) + v144[1] * v145[1], 65535), 16), 4294967295), 4294967295))
									local v147 = table.pack(bit32.band(v146[1], 65535))
									v72 = bit32.band(49257 * v147[1] + bit32.lshift(bit32.band(49257 * bit32.rshift(v146[1], 16) + 24579 * v147[1], 65535), 16), 4294967295)
									local v148 = table.pack(bit32.band(bit32.band(v70, n18), 4294967295))
									local v149 = table.pack(bit32.band(v148[1], 65535))
									n21 = n19 + n20 + v72 + bit32.band(25157 * v149[1] + bit32.lshift(bit32.band(25157 * bit32.rshift(v148[1], 16) + 39899 * v149[1], 65535), 16), 4294967295)
									v73 = bit32.band(n21, 2147483647)
									v74 = bit32.bnot(v73)
									local v150 = table.pack(bit32.band(v74, 4294967295))
									local v151 = table.pack(bit32.band(v150[1], 65535))
									n22 = 1675287778 + bit32.band(65535 * v151[1] + bit32.lshift(bit32.band(65535 * bit32.rshift(v150[1], 16) + 65535 * v151[1], 65535), 16), 4294967295)
									local v152 = table.pack(bit32.band(n21, 4294967295))
									local v153 = table.pack(bit32.band(v152[1], 65535))
									v75 = bit32.band(56547 * v153[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v152[1], 16) + 25562 * v153[1], 65535), 16), 4294967295)
									local v154 = table.pack(bit32.band(bit32.bnot(n21), 4294967295))
									local v155 = table.pack(bit32.band(v154[1], 65535))
									n23 = n22 + v75 + bit32.band(56547 * v155[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v154[1], 16) + 25562 * v155[1], 65535), 16), 4294967295)
									local v156 = table.pack(bit32.band(v74, 4294967295))
									local v157 = table.pack(bit32.band(v156[1], 65535))
									n24 = 818577375 + bit32.band(32735 * v157[1] + bit32.lshift(bit32.band(32735 * bit32.rshift(v156[1], 16) + 12490 * v157[1], 65535), 16), 4294967295)
									local v158 = table.pack(bit32.band(n21, 4294967295))
									local v159 = table.pack(bit32.band(v158[1], 65535))
									v76 = bit32.band(32736 * v159[1] + bit32.lshift(bit32.band(32736 * bit32.rshift(v158[1], 16) + 12490 * v159[1], 65535), 16), 4294967295)
									local v160 = table.pack(bit32.band(bit32.band(n21, 2147483648), 4294967295))
									local v161 = table.pack(bit32.band(v160[1], 65535))
									local v162 = table.pack(bit32.band(n23 - n24 + v76 + bit32.band(32800 * v161[1] + bit32.lshift(bit32.band(32800 * bit32.rshift(v160[1], 16) + 53045 * v161[1], 65535), 16), 4294967295), 4294967295))
									local v163 = table.pack(bit32.band(v162[1], 65535))
									v77 = bit32.band(35718 * v163[1] + bit32.lshift(bit32.band(35718 * bit32.rshift(v162[1], 16) + 56826 * v163[1], 65535), 16), 4294967295)
									local v164 = table.pack(bit32.band(n21, 4294967295))
									local v165 = table.pack(bit32.band(v164[1], 65535))
									local v166 = table.pack(bit32.band(bit32.band(v165[1] * 43674 + bit32.lshift(bit32.band(v165[1] * 53213 + bit32.rshift(v164[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v167 = table.pack(bit32.band(v166[1], 65535))
									n25 = 3201062516 + bit32.band(21612 * v167[1] + bit32.lshift(bit32.band(21612 * bit32.rshift(v166[1], 16) + 41409 * v167[1], 65535), 16), 4294967295)
									local v168 = table.pack(bit32.band(n21, 4294967295))
									local v169 = table.pack(bit32.band(v168[1], 65535))
									n26 = n25 + bit32.band(22132 * v169[1] + bit32.lshift(bit32.band(22132 * bit32.rshift(v168[1], 16) + 48844 * v169[1], 65535), 16), 4294967295) + 442990344
									local v170 = table.pack(bit32.band(v73, 4294967295))
									local v171 = table.pack(bit32.band(v170[1], 65535))
									n27 = bit32.band(43405 * v171[1] + bit32.lshift(bit32.band(43405 * bit32.rshift(v170[1], 16) + 16691 * v171[1], 65535), 16), 4294967295) + 3196435152
									bit32.bor(n21, 2147483647)
									local v172 = table.pack(bit32.band(v73, 4294967295))
									local v173 = table.pack(bit32.band(v172[1], 65535))
									local v174 = table.pack(bit32.band(bit32.band(v173[1] * 43674 + bit32.lshift(bit32.band(v173[1] * 53213 + bit32.rshift(v172[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v175 = table.pack(bit32.band(v174[1], 65535))
									n2 = v77 + n26 + n27 + 1093904780 + bit32.band(22312 * v175[1] + bit32.lshift(bit32.band(22312 * bit32.rshift(v174[1], 16) + 48253 * v175[1], 65535), 16), 4294967295)
								else
									break
								end
							end

							tbl = tbl3[4]
							continue
						end

						v38 = arg[5]
						n3 = 24
						n4 = buffer.len(v38) - 24 - 22
						n5 = n3 + 33096061 % n4

						while true do
							n6 = n3 + (n5 + bit32.band(n2, 255) + 1) % n4
							v39 = buffer.readi8(v38, n5)
							v40 = buffer.readi32(v38, n6)
							v41 = bit32.band(bit32.bxor(bit32.bxor(489466012, v39) + bit32.lshift(bit32.band(v40, 255), 3) + 555967646, n5), 2147483647)
							writeu32 = buffer.writeu32
							v42 = v40
							v43 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v39, v40), v41), 2147483647), 968430592)
							writeu32(v38, n5, v43)
							writei16 = buffer.writei16
							v44 = bit32.rshift(v41, 8)
							v45 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v42, v44), n5), 2147483647), 1759694080)
							writei16(v38, n6, v45)
							n2 = v41
							n5 = n3 + (n5 + bit32.band(v41, 63) + 1) % n4
						end
					else
						flag3 = flag4
					end
				else
					flag4 = flag2

					if flag3 then
						tbl[1] = n7

						if flag3 then
							v48 = tbl2[n7]
							tbl3 = { 1, 0, nil, tbl, #v48 + 0 }

							while true do
								v49 = tbl3[1]
								v50 = tbl3[5]
								n8 = tbl3[2] + v49
								flag5 = v49 <= 0
								tbl3[2] = n8

								if n8 <= v50 then
									v51 = n8
									v52 = bit32.lshift(bit32.band(n2, v51), 1)
									local v78 = table.pack(bit32.band(v51, 4294967295))
									local v79 = table.pack(bit32.band(v78[1], 65535))
									n9 = v52 + bit32.band(12155 * v79[1] + bit32.lshift(bit32.band(12155 * bit32.rshift(v78[1], 16) + 14506 * v79[1], 65535), 16), 4294967295)
									v53 = bit32.band(489466013, n2)
									local v80 = table.pack(bit32.band(n2, 4294967295))
									local v81 = table.pack(bit32.band(v53, 4294967295))
									local v82 = table.pack(bit32.band(v80[1], 65535))
									local v83 = table.pack(bit32.rshift(v80[1], 16))
									local v84 = table.pack(bit32.band(v81[1], 65535))
									local v85 = table.pack(bit32.band(bit32.band(v82[1] * v84[1] + bit32.lshift(bit32.band(v82[1] * bit32.rshift(v81[1], 16) + v83[1] * v84[1], 65535), 16), 4294967295), 4294967295))
									local v86 = table.pack(bit32.band(v85[1], 65535))
									v54 = bit32.band(60968 * v86[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v85[1], 16) + 52495 * v86[1], 65535), 16), 4294967295)
									local v87 = table.pack(bit32.band(n2, 4294967295))
									local v88 = table.pack(bit32.band(v87[1], 65535))
									n10 = n9 + v54 + bit32.band(48813 * v88[1] + bit32.lshift(bit32.band(48813 * bit32.rshift(v87[1], 16) + 37989 * v88[1], 65535), 16), 4294967295)
									v55 = bit32.band(bit32.bnot(n2), 1)
									local v89 = table.pack(bit32.band(n2, 4294967295))
									local v90 = table.pack(bit32.band(v55, 4294967295))
									local v91 = table.pack(bit32.band(v89[1], 65535))
									local v92 = table.pack(bit32.rshift(v89[1], 16))
									local v93 = table.pack(bit32.band(v90[1], 65535))
									local v94 = table.pack(bit32.band(bit32.band(v91[1] * v93[1] + bit32.lshift(bit32.band(v91[1] * bit32.rshift(v90[1], 16) + v92[1] * v93[1], 65535), 16), 4294967295), 4294967295))
									local v95 = table.pack(bit32.band(v94[1], 65535))
									n11 = 2508247598 + bit32.band(60968 * v95[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v94[1], 16) + 52495 * v95[1], 65535), 16), 4294967295)
									local v96 = table.pack(bit32.band(v53, 4294967295))
									local v97 = table.pack(bit32.band(v96[1], 65535))
									v56 = bit32.band(24310 * v97[1] + bit32.lshift(bit32.band(24310 * bit32.rshift(v96[1], 16) + 29012 * v97[1], 65535), 16), 4294967295)
									bit32.bor(n2, v52)
									bit32.bnot(v51)
									local v98 = table.pack(bit32.band(n2, 4294967295))
									local v99 = table.pack(bit32.band(v98[1], 65535))
									local v100 = table.pack(bit32.band(bit32.band(v99[1] * 22370 + bit32.lshift(bit32.band(v99[1] * 58067 + bit32.rshift(v98[1], 16) * 22370, 65535), 16), 4294967295), 4294967295))
									local v101 = table.pack(bit32.band(v100[1], 65535))
									n12 = n10 + n11 + v56 + bit32.band(60968 * v101[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v100[1], 16) + 52495 * v101[1], 65535), 16), 4294967295)
									local v102 = table.pack(bit32.band(n12, 4294967295))
									local v103 = table.pack(bit32.band(v102[1], 65535))
									n13 = 127928343 + bit32.band(23910 * v103[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v102[1], 16) + 20095 * v103[1], 65535), 16), 4294967295)
									local v104 = table.pack(bit32.band(bit32.bor(2147483648, n12), 4294967295))
									local v105 = table.pack(bit32.band(v104[1], 65535))
									v57 = bit32.band(41626 * v105[1] + bit32.lshift(bit32.band(41626 * bit32.rshift(v104[1], 16) + 45440 * v105[1], 65535), 16), 4294967295)
									v58 = bit32.bor(2147483647, n12)
									local v106 = table.pack(bit32.band(bit32.bnot(v58), 4294967295))
									local v107 = table.pack(bit32.band(v106[1], 65535))
									local v108 = table.pack(bit32.band(4422895639 - n13 + v57 + bit32.band(23910 * v107[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v106[1], 16) + 20095 * v107[1], 65535), 16), 4294967295), 4294967295))
									local v109 = table.pack(bit32.band(v108[1], 65535))
									v59 = bit32.band(33239 * v109[1] + bit32.lshift(bit32.band(33239 * bit32.rshift(v108[1], 16) + 55971 * v109[1], 65535), 16), 4294967295)
									local v110 = table.pack(bit32.band(n12, 4294967295))
									local v111 = table.pack(bit32.band(v110[1], 65535))
									n14 = 447350770 + bit32.band(18771 * v111[1] + bit32.lshift(bit32.band(18771 * bit32.rshift(v110[1], 16) + 20694 * v111[1], 65535), 16), 4294967295) + 2539006698 + 9346683268
									v60 = bit32.band(2147483647, n12)
									v61 = bit32.band(3849543541, v60)
									local v112 = table.pack(bit32.band(v61, 4294967295))
									local v113 = table.pack(bit32.band(v112[1], 65535))
									local v114 = table.pack(bit32.band(bit32.band(41098 * v113[1] + bit32.lshift(bit32.band(41098 * bit32.rshift(v112[1], 16) + 6796 * v113[1], 65535), 16), 4294967295), 4294967295))
									local v115 = table.pack(bit32.band(v114[1], 65535))
									v62 = bit32.band(21972 * v115[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v114[1], 16) + 11948 * v115[1], 65535), 16), 4294967295)
									bit32.band(n12, 2147483647)
									local v116 = table.pack(bit32.band(v61, 4294967295))
									local v117 = table.pack(bit32.band(v116[1], 65535))
									n15 = v62 + 0 + 3178001138 + bit32.band(2 * v117[1] + bit32.lshift(bit32.band(2 * bit32.rshift(v116[1], 16) + 0 * v117[1], 65535), 16), 4294967295)
									local v118 = table.pack(bit32.band(v61, 4294967295))
									local v119 = table.pack(bit32.band(v118[1], 65535))
									local v120 = table.pack(bit32.band(bit32.band(v119[1] * 65535 + bit32.lshift(bit32.band(v119[1] * 32767 + bit32.rshift(v118[1], 16) * 65535, 65535), 16), 4294967295), 4294967295))
									local v121 = table.pack(bit32.band(v120[1], 65535))
									n16 = 361090504 + bit32.band(43564 * v121[1] + bit32.lshift(bit32.band(43564 * bit32.rshift(v120[1], 16) + 53587 * v121[1], 65535), 16), 4294967295)
									local v122 = table.pack(bit32.band(v61, 4294967295))
									local v123 = table.pack(bit32.band(v122[1], 65535))
									local v124 = table.pack(bit32.band(bit32.band(v123[1] * 24437 + bit32.lshift(bit32.band(v123[1] * 25971 + bit32.rshift(v122[1], 16) * 24437, 65535), 16), 4294967295), 4294967295))
									local v125 = table.pack(bit32.band(v124[1], 65535))
									n17 = v59 + n14 + n15 + n16 + 3221896868 + 1450886216 + bit32.band(21972 * v125[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v124[1], 16) + 11948 * v125[1], 65535), 16), 4294967295)
									v48[v51] = bit32.bxor(v48[v51], 127928343)
									local v126 = table.pack(bit32.band(v51, 4294967295))
									local v127 = table.pack(bit32.band(v126[1], 65535))
									v63 = bit32.band(v127[1] * 22617 + bit32.lshift(bit32.band(v127[1] * 5106 + bit32.rshift(v126[1], 16) * 22617, 65535), 16), 4294967295)
									n18 = n2 + 555967646
									local v128 = table.pack(bit32.band(n18, 4294967295))
									local v129 = table.pack(bit32.band(v128[1], 65535))
									v64 = bit32.band(40380 * v129[1] + bit32.lshift(bit32.band(40380 * bit32.rshift(v128[1], 16) + 25636 * v129[1], 65535), 16), 4294967295)
									local v130 = table.pack(bit32.band(v63, 4294967295))
									local v131 = table.pack(bit32.band(v130[1], 65535))
									v65 = bit32.band(25156 * v131[1] + bit32.lshift(bit32.band(25156 * bit32.rshift(v130[1], 16) + 39899 * v131[1], 65535), 16), 4294967295)
									v66 = bit32.bor(445423754, v63)
									v67 = bit32.bnot(v66)
									local v132 = table.pack(bit32.band(v63, 4294967295))
									local v133 = table.pack(bit32.band(v67, 4294967295))
									local v134 = table.pack(bit32.band(v132[1], 65535))
									local v135 = table.pack(bit32.rshift(v132[1], 16))
									local v136 = table.pack(bit32.band(v133[1], 65535))
									local v137 = table.pack(bit32.band(bit32.band(v134[1] * v136[1] + bit32.lshift(bit32.band(v134[1] * bit32.rshift(v133[1], 16) + v135[1] * v136[1], 65535), 16), 4294967295), 4294967295))
									local v138 = table.pack(bit32.band(v137[1], 65535))
									v68 = v63
									n19 = v64 + v65 + bit32.band(16279 * v138[1] + bit32.lshift(bit32.band(16279 * bit32.rshift(v137[1], 16) + 40956 * v138[1], 65535), 16), 4294967295)
									v69 = bit32.band(n17, 445423754)
									local v139 = table.pack(bit32.band(bit32.band(bit32.bnot(n18), v68), 4294967295))
									local v140 = table.pack(bit32.band(v139[1], 65535))
									n20 = v69 + bit32.band(40381 * v140[1] + bit32.lshift(bit32.band(40381 * bit32.rshift(v139[1], 16) + 25636 * v140[1], 65535), 16), 4294967295)
									v70 = bit32.bnot(v68)
									v71 = bit32.band(v70, 3849543541)
									local v141 = table.pack(bit32.band(v68, 4294967295))
									local v142 = table.pack(bit32.band(v71, 4294967295))
									local v143 = table.pack(bit32.band(v141[1], 65535))
									local v144 = table.pack(bit32.rshift(v141[1], 16))
									local v145 = table.pack(bit32.band(v142[1], 65535))
									local v146 = table.pack(bit32.band(bit32.band(v143[1] * v145[1] + bit32.lshift(bit32.band(v143[1] * bit32.rshift(v142[1], 16) + v144[1] * v145[1], 65535), 16), 4294967295), 4294967295))
									local v147 = table.pack(bit32.band(v146[1], 65535))
									v72 = bit32.band(49257 * v147[1] + bit32.lshift(bit32.band(49257 * bit32.rshift(v146[1], 16) + 24579 * v147[1], 65535), 16), 4294967295)
									local v148 = table.pack(bit32.band(bit32.band(v70, n18), 4294967295))
									local v149 = table.pack(bit32.band(v148[1], 65535))
									n21 = n19 + n20 + v72 + bit32.band(25157 * v149[1] + bit32.lshift(bit32.band(25157 * bit32.rshift(v148[1], 16) + 39899 * v149[1], 65535), 16), 4294967295)
									v73 = bit32.band(n21, 2147483647)
									v74 = bit32.bnot(v73)
									local v150 = table.pack(bit32.band(v74, 4294967295))
									local v151 = table.pack(bit32.band(v150[1], 65535))
									n22 = 1675287778 + bit32.band(65535 * v151[1] + bit32.lshift(bit32.band(65535 * bit32.rshift(v150[1], 16) + 65535 * v151[1], 65535), 16), 4294967295)
									local v152 = table.pack(bit32.band(n21, 4294967295))
									local v153 = table.pack(bit32.band(v152[1], 65535))
									v75 = bit32.band(56547 * v153[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v152[1], 16) + 25562 * v153[1], 65535), 16), 4294967295)
									local v154 = table.pack(bit32.band(bit32.bnot(n21), 4294967295))
									local v155 = table.pack(bit32.band(v154[1], 65535))
									n23 = n22 + v75 + bit32.band(56547 * v155[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v154[1], 16) + 25562 * v155[1], 65535), 16), 4294967295)
									local v156 = table.pack(bit32.band(v74, 4294967295))
									local v157 = table.pack(bit32.band(v156[1], 65535))
									n24 = 818577375 + bit32.band(32735 * v157[1] + bit32.lshift(bit32.band(32735 * bit32.rshift(v156[1], 16) + 12490 * v157[1], 65535), 16), 4294967295)
									local v158 = table.pack(bit32.band(n21, 4294967295))
									local v159 = table.pack(bit32.band(v158[1], 65535))
									v76 = bit32.band(32736 * v159[1] + bit32.lshift(bit32.band(32736 * bit32.rshift(v158[1], 16) + 12490 * v159[1], 65535), 16), 4294967295)
									local v160 = table.pack(bit32.band(bit32.band(n21, 2147483648), 4294967295))
									local v161 = table.pack(bit32.band(v160[1], 65535))
									local v162 = table.pack(bit32.band(n23 - n24 + v76 + bit32.band(32800 * v161[1] + bit32.lshift(bit32.band(32800 * bit32.rshift(v160[1], 16) + 53045 * v161[1], 65535), 16), 4294967295), 4294967295))
									local v163 = table.pack(bit32.band(v162[1], 65535))
									v77 = bit32.band(35718 * v163[1] + bit32.lshift(bit32.band(35718 * bit32.rshift(v162[1], 16) + 56826 * v163[1], 65535), 16), 4294967295)
									local v164 = table.pack(bit32.band(n21, 4294967295))
									local v165 = table.pack(bit32.band(v164[1], 65535))
									local v166 = table.pack(bit32.band(bit32.band(v165[1] * 43674 + bit32.lshift(bit32.band(v165[1] * 53213 + bit32.rshift(v164[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v167 = table.pack(bit32.band(v166[1], 65535))
									n25 = 3201062516 + bit32.band(21612 * v167[1] + bit32.lshift(bit32.band(21612 * bit32.rshift(v166[1], 16) + 41409 * v167[1], 65535), 16), 4294967295)
									local v168 = table.pack(bit32.band(n21, 4294967295))
									local v169 = table.pack(bit32.band(v168[1], 65535))
									n26 = n25 + bit32.band(22132 * v169[1] + bit32.lshift(bit32.band(22132 * bit32.rshift(v168[1], 16) + 48844 * v169[1], 65535), 16), 4294967295) + 442990344
									local v170 = table.pack(bit32.band(v73, 4294967295))
									local v171 = table.pack(bit32.band(v170[1], 65535))
									n27 = bit32.band(43405 * v171[1] + bit32.lshift(bit32.band(43405 * bit32.rshift(v170[1], 16) + 16691 * v171[1], 65535), 16), 4294967295) + 3196435152
									bit32.bor(n21, 2147483647)
									local v172 = table.pack(bit32.band(v73, 4294967295))
									local v173 = table.pack(bit32.band(v172[1], 65535))
									local v174 = table.pack(bit32.band(bit32.band(v173[1] * 43674 + bit32.lshift(bit32.band(v173[1] * 53213 + bit32.rshift(v172[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v175 = table.pack(bit32.band(v174[1], 65535))
									n2 = v77 + n26 + n27 + 1093904780 + bit32.band(22312 * v175[1] + bit32.lshift(bit32.band(22312 * bit32.rshift(v174[1], 16) + 48253 * v175[1], 65535), 16), 4294967295)
								else
									break
								end
							end

							tbl = tbl3[4]
							continue
						end

						v38 = arg[5]
						n3 = 24
						n4 = buffer.len(v38) - 24 - 22
						n5 = n3 + 33096061 % n4

						while true do
							n6 = n3 + (n5 + bit32.band(n2, 255) + 1) % n4
							v39 = buffer.readi8(v38, n5)
							v40 = buffer.readi32(v38, n6)
							v41 = bit32.band(bit32.bxor(bit32.bxor(489466012, v39) + bit32.lshift(bit32.band(v40, 255), 3) + 555967646, n5), 2147483647)
							writeu32 = buffer.writeu32
							v42 = v40
							v43 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v39, v40), v41), 2147483647), 968430592)
							writeu32(v38, n5, v43)
							writei16 = buffer.writei16
							v44 = bit32.rshift(v41, 8)
							v45 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v42, v44), n5), 2147483647), 1759694080)
							writei16(v38, n6, v45)
							n2 = v41
							n5 = n3 + (n5 + bit32.band(v41, 63) + 1) % n4
						end
					else
						flag3 = flag4
					end
				end
			else
				flag3 = flag

				if flag2 then
					if flag3 then
						tbl[1] = n7

						if flag3 then
							v48 = tbl2[n7]
							tbl3 = { 1, 0, nil, tbl, #v48 + 0 }

							while true do
								v49 = tbl3[1]
								v50 = tbl3[5]
								n8 = tbl3[2] + v49
								flag5 = v49 <= 0
								tbl3[2] = n8

								if n8 <= v50 then
									v51 = n8
									v52 = bit32.lshift(bit32.band(n2, v51), 1)
									local v78 = table.pack(bit32.band(v51, 4294967295))
									local v79 = table.pack(bit32.band(v78[1], 65535))
									n9 = v52 + bit32.band(12155 * v79[1] + bit32.lshift(bit32.band(12155 * bit32.rshift(v78[1], 16) + 14506 * v79[1], 65535), 16), 4294967295)
									v53 = bit32.band(489466013, n2)
									local v80 = table.pack(bit32.band(n2, 4294967295))
									local v81 = table.pack(bit32.band(v53, 4294967295))
									local v82 = table.pack(bit32.band(v80[1], 65535))
									local v83 = table.pack(bit32.rshift(v80[1], 16))
									local v84 = table.pack(bit32.band(v81[1], 65535))
									local v85 = table.pack(bit32.band(bit32.band(v82[1] * v84[1] + bit32.lshift(bit32.band(v82[1] * bit32.rshift(v81[1], 16) + v83[1] * v84[1], 65535), 16), 4294967295), 4294967295))
									local v86 = table.pack(bit32.band(v85[1], 65535))
									v54 = bit32.band(60968 * v86[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v85[1], 16) + 52495 * v86[1], 65535), 16), 4294967295)
									local v87 = table.pack(bit32.band(n2, 4294967295))
									local v88 = table.pack(bit32.band(v87[1], 65535))
									n10 = n9 + v54 + bit32.band(48813 * v88[1] + bit32.lshift(bit32.band(48813 * bit32.rshift(v87[1], 16) + 37989 * v88[1], 65535), 16), 4294967295)
									v55 = bit32.band(bit32.bnot(n2), 1)
									local v89 = table.pack(bit32.band(n2, 4294967295))
									local v90 = table.pack(bit32.band(v55, 4294967295))
									local v91 = table.pack(bit32.band(v89[1], 65535))
									local v92 = table.pack(bit32.rshift(v89[1], 16))
									local v93 = table.pack(bit32.band(v90[1], 65535))
									local v94 = table.pack(bit32.band(bit32.band(v91[1] * v93[1] + bit32.lshift(bit32.band(v91[1] * bit32.rshift(v90[1], 16) + v92[1] * v93[1], 65535), 16), 4294967295), 4294967295))
									local v95 = table.pack(bit32.band(v94[1], 65535))
									n11 = 2508247598 + bit32.band(60968 * v95[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v94[1], 16) + 52495 * v95[1], 65535), 16), 4294967295)
									local v96 = table.pack(bit32.band(v53, 4294967295))
									local v97 = table.pack(bit32.band(v96[1], 65535))
									v56 = bit32.band(24310 * v97[1] + bit32.lshift(bit32.band(24310 * bit32.rshift(v96[1], 16) + 29012 * v97[1], 65535), 16), 4294967295)
									bit32.bor(n2, v52)
									bit32.bnot(v51)
									local v98 = table.pack(bit32.band(n2, 4294967295))
									local v99 = table.pack(bit32.band(v98[1], 65535))
									local v100 = table.pack(bit32.band(bit32.band(v99[1] * 22370 + bit32.lshift(bit32.band(v99[1] * 58067 + bit32.rshift(v98[1], 16) * 22370, 65535), 16), 4294967295), 4294967295))
									local v101 = table.pack(bit32.band(v100[1], 65535))
									n12 = n10 + n11 + v56 + bit32.band(60968 * v101[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v100[1], 16) + 52495 * v101[1], 65535), 16), 4294967295)
									local v102 = table.pack(bit32.band(n12, 4294967295))
									local v103 = table.pack(bit32.band(v102[1], 65535))
									n13 = 127928343 + bit32.band(23910 * v103[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v102[1], 16) + 20095 * v103[1], 65535), 16), 4294967295)
									local v104 = table.pack(bit32.band(bit32.bor(2147483648, n12), 4294967295))
									local v105 = table.pack(bit32.band(v104[1], 65535))
									v57 = bit32.band(41626 * v105[1] + bit32.lshift(bit32.band(41626 * bit32.rshift(v104[1], 16) + 45440 * v105[1], 65535), 16), 4294967295)
									v58 = bit32.bor(2147483647, n12)
									local v106 = table.pack(bit32.band(bit32.bnot(v58), 4294967295))
									local v107 = table.pack(bit32.band(v106[1], 65535))
									local v108 = table.pack(bit32.band(4422895639 - n13 + v57 + bit32.band(23910 * v107[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v106[1], 16) + 20095 * v107[1], 65535), 16), 4294967295), 4294967295))
									local v109 = table.pack(bit32.band(v108[1], 65535))
									v59 = bit32.band(33239 * v109[1] + bit32.lshift(bit32.band(33239 * bit32.rshift(v108[1], 16) + 55971 * v109[1], 65535), 16), 4294967295)
									local v110 = table.pack(bit32.band(n12, 4294967295))
									local v111 = table.pack(bit32.band(v110[1], 65535))
									n14 = 447350770 + bit32.band(18771 * v111[1] + bit32.lshift(bit32.band(18771 * bit32.rshift(v110[1], 16) + 20694 * v111[1], 65535), 16), 4294967295) + 2539006698 + 9346683268
									v60 = bit32.band(2147483647, n12)
									v61 = bit32.band(3849543541, v60)
									local v112 = table.pack(bit32.band(v61, 4294967295))
									local v113 = table.pack(bit32.band(v112[1], 65535))
									local v114 = table.pack(bit32.band(bit32.band(41098 * v113[1] + bit32.lshift(bit32.band(41098 * bit32.rshift(v112[1], 16) + 6796 * v113[1], 65535), 16), 4294967295), 4294967295))
									local v115 = table.pack(bit32.band(v114[1], 65535))
									v62 = bit32.band(21972 * v115[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v114[1], 16) + 11948 * v115[1], 65535), 16), 4294967295)
									bit32.band(n12, 2147483647)
									local v116 = table.pack(bit32.band(v61, 4294967295))
									local v117 = table.pack(bit32.band(v116[1], 65535))
									n15 = v62 + 0 + 3178001138 + bit32.band(2 * v117[1] + bit32.lshift(bit32.band(2 * bit32.rshift(v116[1], 16) + 0 * v117[1], 65535), 16), 4294967295)
									local v118 = table.pack(bit32.band(v61, 4294967295))
									local v119 = table.pack(bit32.band(v118[1], 65535))
									local v120 = table.pack(bit32.band(bit32.band(v119[1] * 65535 + bit32.lshift(bit32.band(v119[1] * 32767 + bit32.rshift(v118[1], 16) * 65535, 65535), 16), 4294967295), 4294967295))
									local v121 = table.pack(bit32.band(v120[1], 65535))
									n16 = 361090504 + bit32.band(43564 * v121[1] + bit32.lshift(bit32.band(43564 * bit32.rshift(v120[1], 16) + 53587 * v121[1], 65535), 16), 4294967295)
									local v122 = table.pack(bit32.band(v61, 4294967295))
									local v123 = table.pack(bit32.band(v122[1], 65535))
									local v124 = table.pack(bit32.band(bit32.band(v123[1] * 24437 + bit32.lshift(bit32.band(v123[1] * 25971 + bit32.rshift(v122[1], 16) * 24437, 65535), 16), 4294967295), 4294967295))
									local v125 = table.pack(bit32.band(v124[1], 65535))
									n17 = v59 + n14 + n15 + n16 + 3221896868 + 1450886216 + bit32.band(21972 * v125[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v124[1], 16) + 11948 * v125[1], 65535), 16), 4294967295)
									v48[v51] = bit32.bxor(v48[v51], 127928343)
									local v126 = table.pack(bit32.band(v51, 4294967295))
									local v127 = table.pack(bit32.band(v126[1], 65535))
									v63 = bit32.band(v127[1] * 22617 + bit32.lshift(bit32.band(v127[1] * 5106 + bit32.rshift(v126[1], 16) * 22617, 65535), 16), 4294967295)
									n18 = n2 + 555967646
									local v128 = table.pack(bit32.band(n18, 4294967295))
									local v129 = table.pack(bit32.band(v128[1], 65535))
									v64 = bit32.band(40380 * v129[1] + bit32.lshift(bit32.band(40380 * bit32.rshift(v128[1], 16) + 25636 * v129[1], 65535), 16), 4294967295)
									local v130 = table.pack(bit32.band(v63, 4294967295))
									local v131 = table.pack(bit32.band(v130[1], 65535))
									v65 = bit32.band(25156 * v131[1] + bit32.lshift(bit32.band(25156 * bit32.rshift(v130[1], 16) + 39899 * v131[1], 65535), 16), 4294967295)
									v66 = bit32.bor(445423754, v63)
									v67 = bit32.bnot(v66)
									local v132 = table.pack(bit32.band(v63, 4294967295))
									local v133 = table.pack(bit32.band(v67, 4294967295))
									local v134 = table.pack(bit32.band(v132[1], 65535))
									local v135 = table.pack(bit32.rshift(v132[1], 16))
									local v136 = table.pack(bit32.band(v133[1], 65535))
									local v137 = table.pack(bit32.band(bit32.band(v134[1] * v136[1] + bit32.lshift(bit32.band(v134[1] * bit32.rshift(v133[1], 16) + v135[1] * v136[1], 65535), 16), 4294967295), 4294967295))
									local v138 = table.pack(bit32.band(v137[1], 65535))
									v68 = v63
									n19 = v64 + v65 + bit32.band(16279 * v138[1] + bit32.lshift(bit32.band(16279 * bit32.rshift(v137[1], 16) + 40956 * v138[1], 65535), 16), 4294967295)
									v69 = bit32.band(n17, 445423754)
									local v139 = table.pack(bit32.band(bit32.band(bit32.bnot(n18), v68), 4294967295))
									local v140 = table.pack(bit32.band(v139[1], 65535))
									n20 = v69 + bit32.band(40381 * v140[1] + bit32.lshift(bit32.band(40381 * bit32.rshift(v139[1], 16) + 25636 * v140[1], 65535), 16), 4294967295)
									v70 = bit32.bnot(v68)
									v71 = bit32.band(v70, 3849543541)
									local v141 = table.pack(bit32.band(v68, 4294967295))
									local v142 = table.pack(bit32.band(v71, 4294967295))
									local v143 = table.pack(bit32.band(v141[1], 65535))
									local v144 = table.pack(bit32.rshift(v141[1], 16))
									local v145 = table.pack(bit32.band(v142[1], 65535))
									local v146 = table.pack(bit32.band(bit32.band(v143[1] * v145[1] + bit32.lshift(bit32.band(v143[1] * bit32.rshift(v142[1], 16) + v144[1] * v145[1], 65535), 16), 4294967295), 4294967295))
									local v147 = table.pack(bit32.band(v146[1], 65535))
									v72 = bit32.band(49257 * v147[1] + bit32.lshift(bit32.band(49257 * bit32.rshift(v146[1], 16) + 24579 * v147[1], 65535), 16), 4294967295)
									local v148 = table.pack(bit32.band(bit32.band(v70, n18), 4294967295))
									local v149 = table.pack(bit32.band(v148[1], 65535))
									n21 = n19 + n20 + v72 + bit32.band(25157 * v149[1] + bit32.lshift(bit32.band(25157 * bit32.rshift(v148[1], 16) + 39899 * v149[1], 65535), 16), 4294967295)
									v73 = bit32.band(n21, 2147483647)
									v74 = bit32.bnot(v73)
									local v150 = table.pack(bit32.band(v74, 4294967295))
									local v151 = table.pack(bit32.band(v150[1], 65535))
									n22 = 1675287778 + bit32.band(65535 * v151[1] + bit32.lshift(bit32.band(65535 * bit32.rshift(v150[1], 16) + 65535 * v151[1], 65535), 16), 4294967295)
									local v152 = table.pack(bit32.band(n21, 4294967295))
									local v153 = table.pack(bit32.band(v152[1], 65535))
									v75 = bit32.band(56547 * v153[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v152[1], 16) + 25562 * v153[1], 65535), 16), 4294967295)
									local v154 = table.pack(bit32.band(bit32.bnot(n21), 4294967295))
									local v155 = table.pack(bit32.band(v154[1], 65535))
									n23 = n22 + v75 + bit32.band(56547 * v155[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v154[1], 16) + 25562 * v155[1], 65535), 16), 4294967295)
									local v156 = table.pack(bit32.band(v74, 4294967295))
									local v157 = table.pack(bit32.band(v156[1], 65535))
									n24 = 818577375 + bit32.band(32735 * v157[1] + bit32.lshift(bit32.band(32735 * bit32.rshift(v156[1], 16) + 12490 * v157[1], 65535), 16), 4294967295)
									local v158 = table.pack(bit32.band(n21, 4294967295))
									local v159 = table.pack(bit32.band(v158[1], 65535))
									v76 = bit32.band(32736 * v159[1] + bit32.lshift(bit32.band(32736 * bit32.rshift(v158[1], 16) + 12490 * v159[1], 65535), 16), 4294967295)
									local v160 = table.pack(bit32.band(bit32.band(n21, 2147483648), 4294967295))
									local v161 = table.pack(bit32.band(v160[1], 65535))
									local v162 = table.pack(bit32.band(n23 - n24 + v76 + bit32.band(32800 * v161[1] + bit32.lshift(bit32.band(32800 * bit32.rshift(v160[1], 16) + 53045 * v161[1], 65535), 16), 4294967295), 4294967295))
									local v163 = table.pack(bit32.band(v162[1], 65535))
									v77 = bit32.band(35718 * v163[1] + bit32.lshift(bit32.band(35718 * bit32.rshift(v162[1], 16) + 56826 * v163[1], 65535), 16), 4294967295)
									local v164 = table.pack(bit32.band(n21, 4294967295))
									local v165 = table.pack(bit32.band(v164[1], 65535))
									local v166 = table.pack(bit32.band(bit32.band(v165[1] * 43674 + bit32.lshift(bit32.band(v165[1] * 53213 + bit32.rshift(v164[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v167 = table.pack(bit32.band(v166[1], 65535))
									n25 = 3201062516 + bit32.band(21612 * v167[1] + bit32.lshift(bit32.band(21612 * bit32.rshift(v166[1], 16) + 41409 * v167[1], 65535), 16), 4294967295)
									local v168 = table.pack(bit32.band(n21, 4294967295))
									local v169 = table.pack(bit32.band(v168[1], 65535))
									n26 = n25 + bit32.band(22132 * v169[1] + bit32.lshift(bit32.band(22132 * bit32.rshift(v168[1], 16) + 48844 * v169[1], 65535), 16), 4294967295) + 442990344
									local v170 = table.pack(bit32.band(v73, 4294967295))
									local v171 = table.pack(bit32.band(v170[1], 65535))
									n27 = bit32.band(43405 * v171[1] + bit32.lshift(bit32.band(43405 * bit32.rshift(v170[1], 16) + 16691 * v171[1], 65535), 16), 4294967295) + 3196435152
									bit32.bor(n21, 2147483647)
									local v172 = table.pack(bit32.band(v73, 4294967295))
									local v173 = table.pack(bit32.band(v172[1], 65535))
									local v174 = table.pack(bit32.band(bit32.band(v173[1] * 43674 + bit32.lshift(bit32.band(v173[1] * 53213 + bit32.rshift(v172[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v175 = table.pack(bit32.band(v174[1], 65535))
									n2 = v77 + n26 + n27 + 1093904780 + bit32.band(22312 * v175[1] + bit32.lshift(bit32.band(22312 * bit32.rshift(v174[1], 16) + 48253 * v175[1], 65535), 16), 4294967295)
								else
									break
								end
							end

							tbl = tbl3[4]
							continue
						end

						v38 = arg[5]
						n3 = 24
						n4 = buffer.len(v38) - 24 - 22
						n5 = n3 + 33096061 % n4

						while true do
							n6 = n3 + (n5 + bit32.band(n2, 255) + 1) % n4
							v39 = buffer.readi8(v38, n5)
							v40 = buffer.readi32(v38, n6)
							v41 = bit32.band(bit32.bxor(bit32.bxor(489466012, v39) + bit32.lshift(bit32.band(v40, 255), 3) + 555967646, n5), 2147483647)
							writeu32 = buffer.writeu32
							v42 = v40
							v43 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v39, v40), v41), 2147483647), 968430592)
							writeu32(v38, n5, v43)
							writei16 = buffer.writei16
							v44 = bit32.rshift(v41, 8)
							v45 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v42, v44), n5), 2147483647), 1759694080)
							writei16(v38, n6, v45)
							n2 = v41
							n5 = n3 + (n5 + bit32.band(v41, 63) + 1) % n4
						end
					else
						flag3 = flag4
					end
				else
					flag4 = flag2

					if flag3 then
						tbl[1] = n7

						if flag3 then
							v48 = tbl2[n7]
							tbl3 = { 1, 0, nil, tbl, #v48 + 0 }

							while true do
								v49 = tbl3[1]
								v50 = tbl3[5]
								n8 = tbl3[2] + v49
								flag5 = v49 <= 0
								tbl3[2] = n8

								if n8 <= v50 then
									v51 = n8
									v52 = bit32.lshift(bit32.band(n2, v51), 1)
									local v78 = table.pack(bit32.band(v51, 4294967295))
									local v79 = table.pack(bit32.band(v78[1], 65535))
									n9 = v52 + bit32.band(12155 * v79[1] + bit32.lshift(bit32.band(12155 * bit32.rshift(v78[1], 16) + 14506 * v79[1], 65535), 16), 4294967295)
									v53 = bit32.band(489466013, n2)
									local v80 = table.pack(bit32.band(n2, 4294967295))
									local v81 = table.pack(bit32.band(v53, 4294967295))
									local v82 = table.pack(bit32.band(v80[1], 65535))
									local v83 = table.pack(bit32.rshift(v80[1], 16))
									local v84 = table.pack(bit32.band(v81[1], 65535))
									local v85 = table.pack(bit32.band(bit32.band(v82[1] * v84[1] + bit32.lshift(bit32.band(v82[1] * bit32.rshift(v81[1], 16) + v83[1] * v84[1], 65535), 16), 4294967295), 4294967295))
									local v86 = table.pack(bit32.band(v85[1], 65535))
									v54 = bit32.band(60968 * v86[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v85[1], 16) + 52495 * v86[1], 65535), 16), 4294967295)
									local v87 = table.pack(bit32.band(n2, 4294967295))
									local v88 = table.pack(bit32.band(v87[1], 65535))
									n10 = n9 + v54 + bit32.band(48813 * v88[1] + bit32.lshift(bit32.band(48813 * bit32.rshift(v87[1], 16) + 37989 * v88[1], 65535), 16), 4294967295)
									v55 = bit32.band(bit32.bnot(n2), 1)
									local v89 = table.pack(bit32.band(n2, 4294967295))
									local v90 = table.pack(bit32.band(v55, 4294967295))
									local v91 = table.pack(bit32.band(v89[1], 65535))
									local v92 = table.pack(bit32.rshift(v89[1], 16))
									local v93 = table.pack(bit32.band(v90[1], 65535))
									local v94 = table.pack(bit32.band(bit32.band(v91[1] * v93[1] + bit32.lshift(bit32.band(v91[1] * bit32.rshift(v90[1], 16) + v92[1] * v93[1], 65535), 16), 4294967295), 4294967295))
									local v95 = table.pack(bit32.band(v94[1], 65535))
									n11 = 2508247598 + bit32.band(60968 * v95[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v94[1], 16) + 52495 * v95[1], 65535), 16), 4294967295)
									local v96 = table.pack(bit32.band(v53, 4294967295))
									local v97 = table.pack(bit32.band(v96[1], 65535))
									v56 = bit32.band(24310 * v97[1] + bit32.lshift(bit32.band(24310 * bit32.rshift(v96[1], 16) + 29012 * v97[1], 65535), 16), 4294967295)
									bit32.bor(n2, v52)
									bit32.bnot(v51)
									local v98 = table.pack(bit32.band(n2, 4294967295))
									local v99 = table.pack(bit32.band(v98[1], 65535))
									local v100 = table.pack(bit32.band(bit32.band(v99[1] * 22370 + bit32.lshift(bit32.band(v99[1] * 58067 + bit32.rshift(v98[1], 16) * 22370, 65535), 16), 4294967295), 4294967295))
									local v101 = table.pack(bit32.band(v100[1], 65535))
									n12 = n10 + n11 + v56 + bit32.band(60968 * v101[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v100[1], 16) + 52495 * v101[1], 65535), 16), 4294967295)
									local v102 = table.pack(bit32.band(n12, 4294967295))
									local v103 = table.pack(bit32.band(v102[1], 65535))
									n13 = 127928343 + bit32.band(23910 * v103[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v102[1], 16) + 20095 * v103[1], 65535), 16), 4294967295)
									local v104 = table.pack(bit32.band(bit32.bor(2147483648, n12), 4294967295))
									local v105 = table.pack(bit32.band(v104[1], 65535))
									v57 = bit32.band(41626 * v105[1] + bit32.lshift(bit32.band(41626 * bit32.rshift(v104[1], 16) + 45440 * v105[1], 65535), 16), 4294967295)
									v58 = bit32.bor(2147483647, n12)
									local v106 = table.pack(bit32.band(bit32.bnot(v58), 4294967295))
									local v107 = table.pack(bit32.band(v106[1], 65535))
									local v108 = table.pack(bit32.band(4422895639 - n13 + v57 + bit32.band(23910 * v107[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v106[1], 16) + 20095 * v107[1], 65535), 16), 4294967295), 4294967295))
									local v109 = table.pack(bit32.band(v108[1], 65535))
									v59 = bit32.band(33239 * v109[1] + bit32.lshift(bit32.band(33239 * bit32.rshift(v108[1], 16) + 55971 * v109[1], 65535), 16), 4294967295)
									local v110 = table.pack(bit32.band(n12, 4294967295))
									local v111 = table.pack(bit32.band(v110[1], 65535))
									n14 = 447350770 + bit32.band(18771 * v111[1] + bit32.lshift(bit32.band(18771 * bit32.rshift(v110[1], 16) + 20694 * v111[1], 65535), 16), 4294967295) + 2539006698 + 9346683268
									v60 = bit32.band(2147483647, n12)
									v61 = bit32.band(3849543541, v60)
									local v112 = table.pack(bit32.band(v61, 4294967295))
									local v113 = table.pack(bit32.band(v112[1], 65535))
									local v114 = table.pack(bit32.band(bit32.band(41098 * v113[1] + bit32.lshift(bit32.band(41098 * bit32.rshift(v112[1], 16) + 6796 * v113[1], 65535), 16), 4294967295), 4294967295))
									local v115 = table.pack(bit32.band(v114[1], 65535))
									v62 = bit32.band(21972 * v115[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v114[1], 16) + 11948 * v115[1], 65535), 16), 4294967295)
									bit32.band(n12, 2147483647)
									local v116 = table.pack(bit32.band(v61, 4294967295))
									local v117 = table.pack(bit32.band(v116[1], 65535))
									n15 = v62 + 0 + 3178001138 + bit32.band(2 * v117[1] + bit32.lshift(bit32.band(2 * bit32.rshift(v116[1], 16) + 0 * v117[1], 65535), 16), 4294967295)
									local v118 = table.pack(bit32.band(v61, 4294967295))
									local v119 = table.pack(bit32.band(v118[1], 65535))
									local v120 = table.pack(bit32.band(bit32.band(v119[1] * 65535 + bit32.lshift(bit32.band(v119[1] * 32767 + bit32.rshift(v118[1], 16) * 65535, 65535), 16), 4294967295), 4294967295))
									local v121 = table.pack(bit32.band(v120[1], 65535))
									n16 = 361090504 + bit32.band(43564 * v121[1] + bit32.lshift(bit32.band(43564 * bit32.rshift(v120[1], 16) + 53587 * v121[1], 65535), 16), 4294967295)
									local v122 = table.pack(bit32.band(v61, 4294967295))
									local v123 = table.pack(bit32.band(v122[1], 65535))
									local v124 = table.pack(bit32.band(bit32.band(v123[1] * 24437 + bit32.lshift(bit32.band(v123[1] * 25971 + bit32.rshift(v122[1], 16) * 24437, 65535), 16), 4294967295), 4294967295))
									local v125 = table.pack(bit32.band(v124[1], 65535))
									n17 = v59 + n14 + n15 + n16 + 3221896868 + 1450886216 + bit32.band(21972 * v125[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v124[1], 16) + 11948 * v125[1], 65535), 16), 4294967295)
									v48[v51] = bit32.bxor(v48[v51], 127928343)
									local v126 = table.pack(bit32.band(v51, 4294967295))
									local v127 = table.pack(bit32.band(v126[1], 65535))
									v63 = bit32.band(v127[1] * 22617 + bit32.lshift(bit32.band(v127[1] * 5106 + bit32.rshift(v126[1], 16) * 22617, 65535), 16), 4294967295)
									n18 = n2 + 555967646
									local v128 = table.pack(bit32.band(n18, 4294967295))
									local v129 = table.pack(bit32.band(v128[1], 65535))
									v64 = bit32.band(40380 * v129[1] + bit32.lshift(bit32.band(40380 * bit32.rshift(v128[1], 16) + 25636 * v129[1], 65535), 16), 4294967295)
									local v130 = table.pack(bit32.band(v63, 4294967295))
									local v131 = table.pack(bit32.band(v130[1], 65535))
									v65 = bit32.band(25156 * v131[1] + bit32.lshift(bit32.band(25156 * bit32.rshift(v130[1], 16) + 39899 * v131[1], 65535), 16), 4294967295)
									v66 = bit32.bor(445423754, v63)
									v67 = bit32.bnot(v66)
									local v132 = table.pack(bit32.band(v63, 4294967295))
									local v133 = table.pack(bit32.band(v67, 4294967295))
									local v134 = table.pack(bit32.band(v132[1], 65535))
									local v135 = table.pack(bit32.rshift(v132[1], 16))
									local v136 = table.pack(bit32.band(v133[1], 65535))
									local v137 = table.pack(bit32.band(bit32.band(v134[1] * v136[1] + bit32.lshift(bit32.band(v134[1] * bit32.rshift(v133[1], 16) + v135[1] * v136[1], 65535), 16), 4294967295), 4294967295))
									local v138 = table.pack(bit32.band(v137[1], 65535))
									v68 = v63
									n19 = v64 + v65 + bit32.band(16279 * v138[1] + bit32.lshift(bit32.band(16279 * bit32.rshift(v137[1], 16) + 40956 * v138[1], 65535), 16), 4294967295)
									v69 = bit32.band(n17, 445423754)
									local v139 = table.pack(bit32.band(bit32.band(bit32.bnot(n18), v68), 4294967295))
									local v140 = table.pack(bit32.band(v139[1], 65535))
									n20 = v69 + bit32.band(40381 * v140[1] + bit32.lshift(bit32.band(40381 * bit32.rshift(v139[1], 16) + 25636 * v140[1], 65535), 16), 4294967295)
									v70 = bit32.bnot(v68)
									v71 = bit32.band(v70, 3849543541)
									local v141 = table.pack(bit32.band(v68, 4294967295))
									local v142 = table.pack(bit32.band(v71, 4294967295))
									local v143 = table.pack(bit32.band(v141[1], 65535))
									local v144 = table.pack(bit32.rshift(v141[1], 16))
									local v145 = table.pack(bit32.band(v142[1], 65535))
									local v146 = table.pack(bit32.band(bit32.band(v143[1] * v145[1] + bit32.lshift(bit32.band(v143[1] * bit32.rshift(v142[1], 16) + v144[1] * v145[1], 65535), 16), 4294967295), 4294967295))
									local v147 = table.pack(bit32.band(v146[1], 65535))
									v72 = bit32.band(49257 * v147[1] + bit32.lshift(bit32.band(49257 * bit32.rshift(v146[1], 16) + 24579 * v147[1], 65535), 16), 4294967295)
									local v148 = table.pack(bit32.band(bit32.band(v70, n18), 4294967295))
									local v149 = table.pack(bit32.band(v148[1], 65535))
									n21 = n19 + n20 + v72 + bit32.band(25157 * v149[1] + bit32.lshift(bit32.band(25157 * bit32.rshift(v148[1], 16) + 39899 * v149[1], 65535), 16), 4294967295)
									v73 = bit32.band(n21, 2147483647)
									v74 = bit32.bnot(v73)
									local v150 = table.pack(bit32.band(v74, 4294967295))
									local v151 = table.pack(bit32.band(v150[1], 65535))
									n22 = 1675287778 + bit32.band(65535 * v151[1] + bit32.lshift(bit32.band(65535 * bit32.rshift(v150[1], 16) + 65535 * v151[1], 65535), 16), 4294967295)
									local v152 = table.pack(bit32.band(n21, 4294967295))
									local v153 = table.pack(bit32.band(v152[1], 65535))
									v75 = bit32.band(56547 * v153[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v152[1], 16) + 25562 * v153[1], 65535), 16), 4294967295)
									local v154 = table.pack(bit32.band(bit32.bnot(n21), 4294967295))
									local v155 = table.pack(bit32.band(v154[1], 65535))
									n23 = n22 + v75 + bit32.band(56547 * v155[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v154[1], 16) + 25562 * v155[1], 65535), 16), 4294967295)
									local v156 = table.pack(bit32.band(v74, 4294967295))
									local v157 = table.pack(bit32.band(v156[1], 65535))
									n24 = 818577375 + bit32.band(32735 * v157[1] + bit32.lshift(bit32.band(32735 * bit32.rshift(v156[1], 16) + 12490 * v157[1], 65535), 16), 4294967295)
									local v158 = table.pack(bit32.band(n21, 4294967295))
									local v159 = table.pack(bit32.band(v158[1], 65535))
									v76 = bit32.band(32736 * v159[1] + bit32.lshift(bit32.band(32736 * bit32.rshift(v158[1], 16) + 12490 * v159[1], 65535), 16), 4294967295)
									local v160 = table.pack(bit32.band(bit32.band(n21, 2147483648), 4294967295))
									local v161 = table.pack(bit32.band(v160[1], 65535))
									local v162 = table.pack(bit32.band(n23 - n24 + v76 + bit32.band(32800 * v161[1] + bit32.lshift(bit32.band(32800 * bit32.rshift(v160[1], 16) + 53045 * v161[1], 65535), 16), 4294967295), 4294967295))
									local v163 = table.pack(bit32.band(v162[1], 65535))
									v77 = bit32.band(35718 * v163[1] + bit32.lshift(bit32.band(35718 * bit32.rshift(v162[1], 16) + 56826 * v163[1], 65535), 16), 4294967295)
									local v164 = table.pack(bit32.band(n21, 4294967295))
									local v165 = table.pack(bit32.band(v164[1], 65535))
									local v166 = table.pack(bit32.band(bit32.band(v165[1] * 43674 + bit32.lshift(bit32.band(v165[1] * 53213 + bit32.rshift(v164[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v167 = table.pack(bit32.band(v166[1], 65535))
									n25 = 3201062516 + bit32.band(21612 * v167[1] + bit32.lshift(bit32.band(21612 * bit32.rshift(v166[1], 16) + 41409 * v167[1], 65535), 16), 4294967295)
									local v168 = table.pack(bit32.band(n21, 4294967295))
									local v169 = table.pack(bit32.band(v168[1], 65535))
									n26 = n25 + bit32.band(22132 * v169[1] + bit32.lshift(bit32.band(22132 * bit32.rshift(v168[1], 16) + 48844 * v169[1], 65535), 16), 4294967295) + 442990344
									local v170 = table.pack(bit32.band(v73, 4294967295))
									local v171 = table.pack(bit32.band(v170[1], 65535))
									n27 = bit32.band(43405 * v171[1] + bit32.lshift(bit32.band(43405 * bit32.rshift(v170[1], 16) + 16691 * v171[1], 65535), 16), 4294967295) + 3196435152
									bit32.bor(n21, 2147483647)
									local v172 = table.pack(bit32.band(v73, 4294967295))
									local v173 = table.pack(bit32.band(v172[1], 65535))
									local v174 = table.pack(bit32.band(bit32.band(v173[1] * 43674 + bit32.lshift(bit32.band(v173[1] * 53213 + bit32.rshift(v172[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
									local v175 = table.pack(bit32.band(v174[1], 65535))
									n2 = v77 + n26 + n27 + 1093904780 + bit32.band(22312 * v175[1] + bit32.lshift(bit32.band(22312 * bit32.rshift(v174[1], 16) + 48253 * v175[1], 65535), 16), 4294967295)
								else
									break
								end
							end

							tbl = tbl3[4]
							continue
						end

						break
					end

					flag3 = flag4
				end
			end

			tbl[1] = n7

			if flag3 then
				v48 = tbl2[n7]
				tbl3 = { 1, 0, nil, tbl, #v48 + 0 }

				while true do
					v49 = tbl3[1]
					v50 = tbl3[5]
					n8 = tbl3[2] + v49
					flag5 = v49 <= 0
					tbl3[2] = n8

					if n8 <= v50 then
						v51 = n8
						v52 = bit32.lshift(bit32.band(n2, v51), 1)
						local v78 = table.pack(bit32.band(v51, 4294967295))
						local v79 = table.pack(bit32.band(v78[1], 65535))
						n9 = v52 + bit32.band(12155 * v79[1] + bit32.lshift(bit32.band(12155 * bit32.rshift(v78[1], 16) + 14506 * v79[1], 65535), 16), 4294967295)
						v53 = bit32.band(489466013, n2)
						local v80 = table.pack(bit32.band(n2, 4294967295))
						local v81 = table.pack(bit32.band(v53, 4294967295))
						local v82 = table.pack(bit32.band(v80[1], 65535))
						local v83 = table.pack(bit32.rshift(v80[1], 16))
						local v84 = table.pack(bit32.band(v81[1], 65535))
						local v85 = table.pack(bit32.band(bit32.band(v82[1] * v84[1] + bit32.lshift(bit32.band(v82[1] * bit32.rshift(v81[1], 16) + v83[1] * v84[1], 65535), 16), 4294967295), 4294967295))
						local v86 = table.pack(bit32.band(v85[1], 65535))
						v54 = bit32.band(60968 * v86[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v85[1], 16) + 52495 * v86[1], 65535), 16), 4294967295)
						local v87 = table.pack(bit32.band(n2, 4294967295))
						local v88 = table.pack(bit32.band(v87[1], 65535))
						n10 = n9 + v54 + bit32.band(48813 * v88[1] + bit32.lshift(bit32.band(48813 * bit32.rshift(v87[1], 16) + 37989 * v88[1], 65535), 16), 4294967295)
						v55 = bit32.band(bit32.bnot(n2), 1)
						local v89 = table.pack(bit32.band(n2, 4294967295))
						local v90 = table.pack(bit32.band(v55, 4294967295))
						local v91 = table.pack(bit32.band(v89[1], 65535))
						local v92 = table.pack(bit32.rshift(v89[1], 16))
						local v93 = table.pack(bit32.band(v90[1], 65535))
						local v94 = table.pack(bit32.band(bit32.band(v91[1] * v93[1] + bit32.lshift(bit32.band(v91[1] * bit32.rshift(v90[1], 16) + v92[1] * v93[1], 65535), 16), 4294967295), 4294967295))
						local v95 = table.pack(bit32.band(v94[1], 65535))
						n11 = 2508247598 + bit32.band(60968 * v95[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v94[1], 16) + 52495 * v95[1], 65535), 16), 4294967295)
						local v96 = table.pack(bit32.band(v53, 4294967295))
						local v97 = table.pack(bit32.band(v96[1], 65535))
						v56 = bit32.band(24310 * v97[1] + bit32.lshift(bit32.band(24310 * bit32.rshift(v96[1], 16) + 29012 * v97[1], 65535), 16), 4294967295)
						bit32.bor(n2, v52)
						bit32.bnot(v51)
						local v98 = table.pack(bit32.band(n2, 4294967295))
						local v99 = table.pack(bit32.band(v98[1], 65535))
						local v100 = table.pack(bit32.band(bit32.band(v99[1] * 22370 + bit32.lshift(bit32.band(v99[1] * 58067 + bit32.rshift(v98[1], 16) * 22370, 65535), 16), 4294967295), 4294967295))
						local v101 = table.pack(bit32.band(v100[1], 65535))
						n12 = n10 + n11 + v56 + bit32.band(60968 * v101[1] + bit32.lshift(bit32.band(60968 * bit32.rshift(v100[1], 16) + 52495 * v101[1], 65535), 16), 4294967295)
						local v102 = table.pack(bit32.band(n12, 4294967295))
						local v103 = table.pack(bit32.band(v102[1], 65535))
						n13 = 127928343 + bit32.band(23910 * v103[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v102[1], 16) + 20095 * v103[1], 65535), 16), 4294967295)
						local v104 = table.pack(bit32.band(bit32.bor(2147483648, n12), 4294967295))
						local v105 = table.pack(bit32.band(v104[1], 65535))
						v57 = bit32.band(41626 * v105[1] + bit32.lshift(bit32.band(41626 * bit32.rshift(v104[1], 16) + 45440 * v105[1], 65535), 16), 4294967295)
						v58 = bit32.bor(2147483647, n12)
						local v106 = table.pack(bit32.band(bit32.bnot(v58), 4294967295))
						local v107 = table.pack(bit32.band(v106[1], 65535))
						local v108 = table.pack(bit32.band(4422895639 - n13 + v57 + bit32.band(23910 * v107[1] + bit32.lshift(bit32.band(23910 * bit32.rshift(v106[1], 16) + 20095 * v107[1], 65535), 16), 4294967295), 4294967295))
						local v109 = table.pack(bit32.band(v108[1], 65535))
						v59 = bit32.band(33239 * v109[1] + bit32.lshift(bit32.band(33239 * bit32.rshift(v108[1], 16) + 55971 * v109[1], 65535), 16), 4294967295)
						local v110 = table.pack(bit32.band(n12, 4294967295))
						local v111 = table.pack(bit32.band(v110[1], 65535))
						n14 = 447350770 + bit32.band(18771 * v111[1] + bit32.lshift(bit32.band(18771 * bit32.rshift(v110[1], 16) + 20694 * v111[1], 65535), 16), 4294967295) + 2539006698 + 9346683268
						v60 = bit32.band(2147483647, n12)
						v61 = bit32.band(3849543541, v60)
						local v112 = table.pack(bit32.band(v61, 4294967295))
						local v113 = table.pack(bit32.band(v112[1], 65535))
						local v114 = table.pack(bit32.band(bit32.band(41098 * v113[1] + bit32.lshift(bit32.band(41098 * bit32.rshift(v112[1], 16) + 6796 * v113[1], 65535), 16), 4294967295), 4294967295))
						local v115 = table.pack(bit32.band(v114[1], 65535))
						v62 = bit32.band(21972 * v115[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v114[1], 16) + 11948 * v115[1], 65535), 16), 4294967295)
						bit32.band(n12, 2147483647)
						local v116 = table.pack(bit32.band(v61, 4294967295))
						local v117 = table.pack(bit32.band(v116[1], 65535))
						n15 = v62 + 0 + 3178001138 + bit32.band(2 * v117[1] + bit32.lshift(bit32.band(2 * bit32.rshift(v116[1], 16) + 0 * v117[1], 65535), 16), 4294967295)
						local v118 = table.pack(bit32.band(v61, 4294967295))
						local v119 = table.pack(bit32.band(v118[1], 65535))
						local v120 = table.pack(bit32.band(bit32.band(v119[1] * 65535 + bit32.lshift(bit32.band(v119[1] * 32767 + bit32.rshift(v118[1], 16) * 65535, 65535), 16), 4294967295), 4294967295))
						local v121 = table.pack(bit32.band(v120[1], 65535))
						n16 = 361090504 + bit32.band(43564 * v121[1] + bit32.lshift(bit32.band(43564 * bit32.rshift(v120[1], 16) + 53587 * v121[1], 65535), 16), 4294967295)
						local v122 = table.pack(bit32.band(v61, 4294967295))
						local v123 = table.pack(bit32.band(v122[1], 65535))
						local v124 = table.pack(bit32.band(bit32.band(v123[1] * 24437 + bit32.lshift(bit32.band(v123[1] * 25971 + bit32.rshift(v122[1], 16) * 24437, 65535), 16), 4294967295), 4294967295))
						local v125 = table.pack(bit32.band(v124[1], 65535))
						n17 = v59 + n14 + n15 + n16 + 3221896868 + 1450886216 + bit32.band(21972 * v125[1] + bit32.lshift(bit32.band(21972 * bit32.rshift(v124[1], 16) + 11948 * v125[1], 65535), 16), 4294967295)
						v48[v51] = bit32.bxor(v48[v51], 127928343)
						local v126 = table.pack(bit32.band(v51, 4294967295))
						local v127 = table.pack(bit32.band(v126[1], 65535))
						v63 = bit32.band(v127[1] * 22617 + bit32.lshift(bit32.band(v127[1] * 5106 + bit32.rshift(v126[1], 16) * 22617, 65535), 16), 4294967295)
						n18 = n2 + 555967646
						local v128 = table.pack(bit32.band(n18, 4294967295))
						local v129 = table.pack(bit32.band(v128[1], 65535))
						v64 = bit32.band(40380 * v129[1] + bit32.lshift(bit32.band(40380 * bit32.rshift(v128[1], 16) + 25636 * v129[1], 65535), 16), 4294967295)
						local v130 = table.pack(bit32.band(v63, 4294967295))
						local v131 = table.pack(bit32.band(v130[1], 65535))
						v65 = bit32.band(25156 * v131[1] + bit32.lshift(bit32.band(25156 * bit32.rshift(v130[1], 16) + 39899 * v131[1], 65535), 16), 4294967295)
						v66 = bit32.bor(445423754, v63)
						v67 = bit32.bnot(v66)
						local v132 = table.pack(bit32.band(v63, 4294967295))
						local v133 = table.pack(bit32.band(v67, 4294967295))
						local v134 = table.pack(bit32.band(v132[1], 65535))
						local v135 = table.pack(bit32.rshift(v132[1], 16))
						local v136 = table.pack(bit32.band(v133[1], 65535))
						local v137 = table.pack(bit32.band(bit32.band(v134[1] * v136[1] + bit32.lshift(bit32.band(v134[1] * bit32.rshift(v133[1], 16) + v135[1] * v136[1], 65535), 16), 4294967295), 4294967295))
						local v138 = table.pack(bit32.band(v137[1], 65535))
						v68 = v63
						n19 = v64 + v65 + bit32.band(16279 * v138[1] + bit32.lshift(bit32.band(16279 * bit32.rshift(v137[1], 16) + 40956 * v138[1], 65535), 16), 4294967295)
						v69 = bit32.band(n17, 445423754)
						local v139 = table.pack(bit32.band(bit32.band(bit32.bnot(n18), v68), 4294967295))
						local v140 = table.pack(bit32.band(v139[1], 65535))
						n20 = v69 + bit32.band(40381 * v140[1] + bit32.lshift(bit32.band(40381 * bit32.rshift(v139[1], 16) + 25636 * v140[1], 65535), 16), 4294967295)
						v70 = bit32.bnot(v68)
						v71 = bit32.band(v70, 3849543541)
						local v141 = table.pack(bit32.band(v68, 4294967295))
						local v142 = table.pack(bit32.band(v71, 4294967295))
						local v143 = table.pack(bit32.band(v141[1], 65535))
						local v144 = table.pack(bit32.rshift(v141[1], 16))
						local v145 = table.pack(bit32.band(v142[1], 65535))
						local v146 = table.pack(bit32.band(bit32.band(v143[1] * v145[1] + bit32.lshift(bit32.band(v143[1] * bit32.rshift(v142[1], 16) + v144[1] * v145[1], 65535), 16), 4294967295), 4294967295))
						local v147 = table.pack(bit32.band(v146[1], 65535))
						v72 = bit32.band(49257 * v147[1] + bit32.lshift(bit32.band(49257 * bit32.rshift(v146[1], 16) + 24579 * v147[1], 65535), 16), 4294967295)
						local v148 = table.pack(bit32.band(bit32.band(v70, n18), 4294967295))
						local v149 = table.pack(bit32.band(v148[1], 65535))
						n21 = n19 + n20 + v72 + bit32.band(25157 * v149[1] + bit32.lshift(bit32.band(25157 * bit32.rshift(v148[1], 16) + 39899 * v149[1], 65535), 16), 4294967295)
						v73 = bit32.band(n21, 2147483647)
						v74 = bit32.bnot(v73)
						local v150 = table.pack(bit32.band(v74, 4294967295))
						local v151 = table.pack(bit32.band(v150[1], 65535))
						n22 = 1675287778 + bit32.band(65535 * v151[1] + bit32.lshift(bit32.band(65535 * bit32.rshift(v150[1], 16) + 65535 * v151[1], 65535), 16), 4294967295)
						local v152 = table.pack(bit32.band(n21, 4294967295))
						local v153 = table.pack(bit32.band(v152[1], 65535))
						v75 = bit32.band(56547 * v153[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v152[1], 16) + 25562 * v153[1], 65535), 16), 4294967295)
						local v154 = table.pack(bit32.band(bit32.bnot(n21), 4294967295))
						local v155 = table.pack(bit32.band(v154[1], 65535))
						n23 = n22 + v75 + bit32.band(56547 * v155[1] + bit32.lshift(bit32.band(56547 * bit32.rshift(v154[1], 16) + 25562 * v155[1], 65535), 16), 4294967295)
						local v156 = table.pack(bit32.band(v74, 4294967295))
						local v157 = table.pack(bit32.band(v156[1], 65535))
						n24 = 818577375 + bit32.band(32735 * v157[1] + bit32.lshift(bit32.band(32735 * bit32.rshift(v156[1], 16) + 12490 * v157[1], 65535), 16), 4294967295)
						local v158 = table.pack(bit32.band(n21, 4294967295))
						local v159 = table.pack(bit32.band(v158[1], 65535))
						v76 = bit32.band(32736 * v159[1] + bit32.lshift(bit32.band(32736 * bit32.rshift(v158[1], 16) + 12490 * v159[1], 65535), 16), 4294967295)
						local v160 = table.pack(bit32.band(bit32.band(n21, 2147483648), 4294967295))
						local v161 = table.pack(bit32.band(v160[1], 65535))
						local v162 = table.pack(bit32.band(n23 - n24 + v76 + bit32.band(32800 * v161[1] + bit32.lshift(bit32.band(32800 * bit32.rshift(v160[1], 16) + 53045 * v161[1], 65535), 16), 4294967295), 4294967295))
						local v163 = table.pack(bit32.band(v162[1], 65535))
						v77 = bit32.band(35718 * v163[1] + bit32.lshift(bit32.band(35718 * bit32.rshift(v162[1], 16) + 56826 * v163[1], 65535), 16), 4294967295)
						local v164 = table.pack(bit32.band(n21, 4294967295))
						local v165 = table.pack(bit32.band(v164[1], 65535))
						local v166 = table.pack(bit32.band(bit32.band(v165[1] * 43674 + bit32.lshift(bit32.band(v165[1] * 53213 + bit32.rshift(v164[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
						local v167 = table.pack(bit32.band(v166[1], 65535))
						n25 = 3201062516 + bit32.band(21612 * v167[1] + bit32.lshift(bit32.band(21612 * bit32.rshift(v166[1], 16) + 41409 * v167[1], 65535), 16), 4294967295)
						local v168 = table.pack(bit32.band(n21, 4294967295))
						local v169 = table.pack(bit32.band(v168[1], 65535))
						n26 = n25 + bit32.band(22132 * v169[1] + bit32.lshift(bit32.band(22132 * bit32.rshift(v168[1], 16) + 48844 * v169[1], 65535), 16), 4294967295) + 442990344
						local v170 = table.pack(bit32.band(v73, 4294967295))
						local v171 = table.pack(bit32.band(v170[1], 65535))
						n27 = bit32.band(43405 * v171[1] + bit32.lshift(bit32.band(43405 * bit32.rshift(v170[1], 16) + 16691 * v171[1], 65535), 16), 4294967295) + 3196435152
						bit32.bor(n21, 2147483647)
						local v172 = table.pack(bit32.band(v73, 4294967295))
						local v173 = table.pack(bit32.band(v172[1], 65535))
						local v174 = table.pack(bit32.band(bit32.band(v173[1] * 43674 + bit32.lshift(bit32.band(v173[1] * 53213 + bit32.rshift(v172[1], 16) * 43674, 65535), 16), 4294967295), 4294967295))
						local v175 = table.pack(bit32.band(v174[1], 65535))
						n2 = v77 + n26 + n27 + 1093904780 + bit32.band(22312 * v175[1] + bit32.lshift(bit32.band(22312 * bit32.rshift(v174[1], 16) + 48253 * v175[1], 65535), 16), 4294967295)
					else
						break
					end
				end

				tbl = tbl3[4]
				continue
			end

			v38 = arg[5]
			n3 = 24
			n4 = buffer.len(v38) - 24 - 22
			n5 = n3 + 33096061 % n4

			while true do
				n6 = n3 + (n5 + bit32.band(n2, 255) + 1) % n4
				v39 = buffer.readi8(v38, n5)
				v40 = buffer.readi32(v38, n6)
				v41 = bit32.band(bit32.bxor(bit32.bxor(489466012, v39) + bit32.lshift(bit32.band(v40, 255), 3) + 555967646, n5), 2147483647)
				writeu32 = buffer.writeu32
				v42 = v40
				v43 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v39, v40), v41), 2147483647), 968430592)
				writeu32(v38, n5, v43)
				writei16 = buffer.writei16
				v44 = bit32.rshift(v41, 8)
				v45 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v42, v44), n5), 2147483647), 1759694080)
				writei16(v38, n6, v45)
				n2 = v41
				n5 = n3 + (n5 + bit32.band(v41, 63) + 1) % n4
			end
		end

		v38 = arg[5]
		n3 = 24
		n4 = buffer.len(v38) - 24 - 22
		n5 = n3 + 33096061 % n4

		while true do
			n6 = n3 + (n5 + bit32.band(n2, 255) + 1) % n4
			v39 = buffer.readi8(v38, n5)
			v40 = buffer.readi32(v38, n6)
			v41 = bit32.band(bit32.bxor(bit32.bxor(489466012, v39) + bit32.lshift(bit32.band(v40, 255), 3) + 555967646, n5), 2147483647)
			writeu32 = buffer.writeu32
			v42 = v40
			v43 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v39, v40), v41), 2147483647), 968430592)
			writeu32(v38, n5, v43)
			writei16 = buffer.writei16
			v44 = bit32.rshift(v41, 8)
			v45 = bit32.bor(bit32.band(bit32.bxor(bit32.bxor(v42, v44), n5), 2147483647), 1759694080)
			writei16(v38, n6, v45)
			n2 = v41
			n5 = n3 + (n5 + bit32.band(v41, 63) + 1) % n4
		end
	end

	fn8(nil, nil, nil, nil, 275351386, nil)

	while true do
	end
end

local fn8

fn8 = function()
	fn6(132891451, 4)
	n = 160167421
	fn7()
end

local n2
n2 = nil - nil + 2961830091
local tbl
tbl = { [false] = true, [true] = false }
local fn9
local tbl2 = {}

fn9 = function(arg, arg2)
	if not nil then
		if nil then
			if nil then
				return false
			end

			if nil then
				return true
			end
			return false
		end
	end

	tbl2[arg] = true
	local v38 = tbl2[arg2]
	tbl2[arg] = nil
	return v38
end

local fn10

fn10 = function(arg)
	if not nil then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local kind = type(arg)
	fn9("table", kind)

	if not nil then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local v38 = getmetatable(arg)
	fn9(nil, v38)

	if not nil then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	pcall(setmetatable, arg, nil)
end

local fn11

fn11 = function(arg, arg2)
	local state = 1
	local v38, n3, v39, n4, tbl3, v40, v41, n5, flag, flag2, flag3, flag4

	while true do
		if state == 1 then
			v38 = arg
			n3 = arg2
			v39 = table.pack()
			n4 = 1
			tbl3 = nil
			v40 = nil
			v41 = nil
			state = 2
		elseif state == 2 then
			if n4 <= 0 then
				state = 7
			else
				state = 3
			end
		elseif state == 3 then
			v39 = table.pack(string.byte(n3, 1, -1))
			n4 = bit32.bxor(v38, 401756626) ~= 171831513

			if n4 then
				state = 4
			else
				state = 5
			end
		elseif state == 4 then
			n4 = 6
			state = 5
		elseif state == 5 then
			n3 = 2166136261

			if n4 then
				state = 14
			else
				state = 6
			end
		elseif state == 6 then
			n4 = 3
			state = 28
		elseif state == 7 then
			tbl3 = tbl3[4]
			n4 = 8
			state = 8
		elseif state == 8 then
			if n4 <= 6 then
				state = 26
			else
				state = 9
			end
		elseif state == 9 then
			if n4 <= 7 then
				state = 17
			else
				state = 10
			end
		elseif state == 10 then
			if n4 <= 8 then
				state = 16
			else
				state = 11
			end
		elseif state == 11 then
			n3 = bit32.bxor(2166136261, v40[v41])

			if n3 < 134217728 then
				state = 13
			else
				state = 12
			end
		elseif state == 12 then
			n4 = 2
			state = 28
		elseif state == 13 then
			n4 = 5
			state = 14
		elseif state == 14 then
			if n4 <= 4 then
				state = 15
			else
				state = 8
			end
		elseif state == 15 then
			if n4 <= 1 then
				state = 2
			else
				state = 28
			end
		elseif state == 16 then
			n3 = 3221447138
			n4 = 4
			state = 28
		elseif state == 17 then
			local v42 = tbl3[1]
			local v43 = tbl3[3]
			n5 = tbl3[2] + v42
			flag = v42 <= 0
			flag2 = not flag
			flag3 = n5 >= v43
			flag4 = n5 <= v43

			if flag then
				state = 19
			else
				state = 18
			end
		elseif state == 18 then
			flag3 = flag

			if flag2 then
				state = 21
			else
				state = 20
			end
		elseif state == 19 then
			if flag2 then
				state = 21
			else
				state = 20
			end
		elseif state == 20 then
			flag4 = flag2

			if flag3 then
				state = 23
			else
				state = 22
			end
		elseif state == 21 then
			if flag3 then
				state = 23
			else
				state = 22
			end
		elseif state == 22 then
			flag3 = flag4
			state = 23
		elseif state == 23 then
			tbl3[2] = n5

			if flag3 then
				state = 25
			else
				state = 24
			end
		elseif state == 24 then
			n4 = 0
			state = 2
		elseif state == 25 then
			n4 = 9
			v41 = n5
			state = 8
		elseif state == 26 then
			if n4 <= 5 then
				state = 33
			else
				state = 27
			end
		elseif state == 27 then
			v38 = bit32.bxor(v38, 3846035827)
			n4 = 3
			state = 28
		elseif state == 28 then
			if n4 <= 2 then
				state = 32
			else
				state = 29
			end
		elseif state == 29 then
			if n4 <= 3 then
				state = 31
			else
				state = 30
			end
		elseif state == 30 then
			return n3
		elseif state == 31 then
			v40 = v39
			n4 = 7
			tbl3 = { 1, 0, v40.n + 0, tbl3, nil }
			state = 8
		elseif state == 32 then
			local n6 = n3 % 65536
			n3 = (((n3 - n6) / 65536 * 403 + n6 * 256) * 65536 + n6 * 403) % 4294967296
			n4 = 7
			state = 8
		elseif state == 33 then
			n3 = n3 * 16777619 % 4294967296
			n4 = 7
			state = 8
		end
	end
end

local new, new2, color, rect, udim2, udim, new3, v38, v39, fn12

do
	local function fn13(arg, arg2)
		local v40 = table.pack(b_1())

		if v40[1] then
			local v41 = v40[2]

			while true do
				arg2[fn11(500146443, v41)] = nil
				local v42 = table.pack(b_1())

				if v42[1] then
					v41 = v42[2]
				else
					break
				end
			end
		end

		local v41 = table.pack(b_1())

		if v41[1] then
			repeat
				fn6(132891451, 4)
				n = 160167421
				fn7()
				local v42 = table.pack(b_1())
			until not v42[1]
		end
	end

	fn10(v28, 477950703)
	fn10(v29, 477950703)
	fn10(v30, 477950703)
	fn10(v31, 477950703)
	fn10(v32, 477950703)
	local new4 = v28.new
	new = v29.new
	new2 = v30.new
	color = Color3.new
	rect = Rect.new
	udim2 = UDim2.new
	udim = UDim.new
	new3 = Path2DControlPoint.new
	local tbl3 = {}
	v38 = fn13
	v39 = new4

	fn12 = function(arg, arg2, arg3)
		if nil then
			local kind = type(arg2)
			fn9("function", kind)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			local n3 = nil // nil
			local ok, result = pcall(setfenv, arg2, tbl3)
			local str

			if nil then
				str = "'setfenv' cannot change environment of given object"
				fn6(132891451, 4)
				n = 160167421
				fn7()
			else
				str = "'setfenv' cannot change environment of given object"
			end

			fn9(str, result)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			local v40, v41, v42, v43, v44, v45 = info(arg2, "slnaf")
			local v46 = fn9
			fn9("[C]", v40)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			fn9(-1, v41)
			local n4

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				n4 = nil + arg - 513498414
			end

			fn9(0, v43)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			fn9(true, v44)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			fn9(arg2, v45)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				local v47 = table.pack(bit32.band(n4, 4294967295))
				local v48 = table.pack(bit32.band(arg, 4294967295))
				local v49 = table.pack(bit32.band(v47[1], 65535))
				local v50 = table.pack(bit32.rshift(v47[1], 16))
				local v51 = table.pack(bit32.band(v48[1], 65535))
				local v52 = bit32.band(v49[1] * v51[1] + bit32.lshift(bit32.band(v49[1] * bit32.rshift(v48[1], 16) + v50[1] * v51[1], 65535), 16), 4294967295)
				fn7()
				n4 = v52 + 3088881533
			end

			if arg3 then
				fn9(arg3, v42)

				if not nil then
					fn6(132891451, 4)
					n = 160167421
					fn7()
				end
			end

			if nil then
				local n5 = n3 + arg
				local v47 = v35(arg2)
				fn9(true, v47)

				if not nil then
					fn6(132891451, 4)
					n = 160167421
					fn7()
				end

				local v48 = v34(arg2)
				fn9(false, v48)

				if not nil then
					fn6(132891451, 4)
					n = 160167421
					fn7()
				end

				n3 = n5 - 513498414
			end
		end
	end
end

fn12(513498414, getmetatable, "getmetatable")
fn12(513498414, setmetatable, "setmetatable")
fn12(513498414, tonumber, "tonumber")
fn12(513498414, tostring, "tostring")
fn12(513498414, rawset, "rawset")
fn12(513498414, rawget, "rawget")
fn12(513498414, select, "select")
fn12(513498414, xpcall, "xpcall")
fn12(513498414, assert, "assert")
fn12(513498414, error, "error")
fn12(513498414, pcall, "pcall")
fn12(513498414, type, "type")
fn12(513498414, next, "next")
fn12(513498414, getfenv, "getfenv")
fn12(513498414, setfenv, "setfenv")
fn12(513498414, typeof, "typeof")
fn12(513498414, string.gmatch, "gmatch")
fn12(513498414, string.format, "format")
fn12(513498414, string.match, "match")
fn12(513498414, string.find, "find")
fn12(513498414, string.char, "char")
fn12(513498414, string.byte, "byte")
fn12(513498414, string.gsub, "gsub")
fn12(513498414, string.sub, "sub")
fn12(513498414, string.rep, "rep")
fn12(513498414, string.unpack, "unpack")
fn12(513498414, string.pack, "pack")
fn12(513498414, table.concat, "concat")
fn12(513498414, table.insert, "insert")
fn12(513498414, table.pack, "pack")
fn12(513498414, table.clear, "clear")
fn12(513498414, table.create, "create")
fn12(513498414, table.move, "move")
fn12(513498414, bit32.bor, "bor")
fn12(513498414, bit32.bnot, "bnot")
fn12(513498414, bit32.bxor, "bxor")
fn12(513498414, bit32.band, "band")
fn12(513498414, bit32.lshift, "lshift")
fn12(513498414, bit32.rshift, "rshift")
fn12(513498414, bit32.rrotate, "rrotate")
fn12(513498414, bit32.lrotate, "lrotate")
fn12(513498414, bit32.countlz, "countlz")
fn12(513498414, bit32.countrz, "countrz")
fn12(513498414, buffer.len, "len")
fn12(513498414, buffer.fill, "fill")
fn12(513498414, buffer.copy, "copy")
fn12(513498414, buffer.create, "create")
fn12(513498414, buffer.tostring, "tostring")
fn12(513498414, buffer.fromstring, "fromstring")
fn12(513498414, buffer.readstring, "readstring")
fn12(513498414, buffer.writestring, "writestring")
fn12(513498414, buffer.readi8, "readi8")
fn12(513498414, buffer.readu8, "readu8")
fn12(513498414, buffer.readi16, "readi16")
fn12(513498414, buffer.readu16, "readu16")
local n3
local readi32 = buffer.readi32
n3 = bit32.bor(n2 // 10, 3382923518)
fn12(513498414, readi32, "readi32")
fn12(513498414, buffer.readu32, "readu32")
fn12(513498414, buffer.readf32, "readf32")
fn12(513498414, buffer.readf64, "readf64")
fn12(513498414, buffer.writei8, "writei8")
fn12(513498414, buffer.writeu8, "writeu8")
fn12(513498414, buffer.writei16, "writei16")
fn12(513498414, buffer.writeu16, "writeu16")
fn12(513498414, buffer.writei32, "writei32")
fn12(513498414, buffer.writeu32, "writeu32")
fn12(513498414, buffer.writef32, "writef32")
fn12(513498414, buffer.writef64, "writef64")
fn12(513498414, buffer.readbits, "readbits")
fn12(513498414, buffer.writebits, "writebits")
fn12(513498414, coroutine.isyieldable, "isyieldable")
fn12(513498414, coroutine.running, "running")
fn12(513498414, coroutine.create, "create")
fn12(513498414, coroutine.status, "status")
fn12(513498414, coroutine.yield, "yield")
fn12(513498414, coroutine.close, "close")
fn12(513498414, coroutine.resume, "resume")
fn12(513498414, coroutine.wrap, "wrap")
fn12(513498414, cancel, "cancel")
fn12(513498414, spawn, "spawn")
fn12(513498414, defer, "defer")
fn12(513498414, delay, "delay")
fn12(513498414, wait, "wait")
fn12(513498414, unpack, "unpack")
fn12(513498414, info, "info")
fn12(513498414, traceback, "traceback")
fn12(513498414, v36)
local n4, n5, n6

do
	local v40 = pcall
	local v41 = xpcall
	n4 = 58454937
	n5 = 212591366
	new2(0.62579740387392646, 0.64859147504654968, 0.77270386208627984)
	v39("Folder")
	local ScreenGui = v39("ScreenGui")
	local Frame = v39("Frame")
	local Path2D = v39("Path2D")
	n6 = 3084449567
	Frame.Parent = ScreenGui
	Path2D.Parent = Frame
	vector.create(0.065431521023827433, 0.99492673572515222, 0.49531708515841344)

	local function fn13()
		assert(0.87775190926538116)
		getfenv(0)
		select("#", 0.78892090635495526, 0.8659057461301215, 0.23362231181891635)
		tonumber(0.59586789375827243)
		tostring(0.0043785375603599963)
		rawequal(scratch, scratch)
		local tbl3 = {}
		next(tbl3)
		pairs(tbl3)(tbl3)
		ipairs(tbl3)(tbl3, 1)
		rawlen(tbl3)
		rawget(tbl3, 0.34669303087154213)
		rawset(tbl3, 0.29138403577809302, 0.11403539353259273)
		getmetatable(tbl3)
		setmetatable(tbl3, tbl3)
		setmetatable(tbl3, nil)
		info(5833, "slnaf")
		local v42 = buffer.create(197)
		buffer.len(v42)
		buffer.fromstring("")
		buffer.tostring(v42)
		buffer.readi8(v42, 0)
		buffer.readu8(v42, 3)
		buffer.readi16(v42, 15)
		buffer.readu16(v42, 15)
		buffer.readi32(v42, 17)
		buffer.readu32(v42, 19)
		buffer.readf32(v42, 10)
		buffer.readf64(v42, 22)
		buffer.writei8(v42, 15, -16)
		buffer.writeu8(v42, 29, 230)
		buffer.writei16(v42, 20, -4485)
		buffer.writeu16(v42, 25, 52492)
		buffer.writei32(v42, 6, -2079772322)
		buffer.writeu32(v42, 11, 1142360590)
		buffer.writef32(v42, 13, 43958)
		buffer.writef64(v42, 29, 54931)
		buffer.readstring(v42, 5, 16)
		buffer.writestring(v42, 9, "Luraph", 4)
		buffer.readbits(v42, 10, 29)
		buffer.writebits(v42, 117, 1, 1235102863)
		buffer.copy(v42, 32, v42, 0, 16)
		buffer.fill(v42, 19, 180, 1)
		local v43 = v32.new()
		v43:NextInteger(16, 259)
		v43:NextNumber(35, 733)
		v43:NextUnitVector()
		v43:NextNumber()
		v43:Shuffle({})
		v43:Clone()
		local n7 = Vector3.new(0.12447457, 0.7966942, 0.76104194) + Vector3.new(0.7588041, 0.8764614, 0.57415444)
		local vector_ = Vector3.new(0.12447457, 0.7966942, 0.76104194)
		local vector_2 = Vector3.new(0.7588041, 0.8764614, 0.57415444)
		local vector_3 = Vector3.new(1, 0, 0)
		local vector_4 = Vector3.new(0, 1, 0)
		local v44 = v31.new()
		local v45 = v31.new(vector_)
		v31.Angles(0.81498799073259232, 0.84728299453361833, 0.1774086349829368)
		local xyz = Enum.RotationOrder.XYZ
		v31.new(vector_, n7)
		v31.new(vector_.X, vector_.Y, vector_.Z)
		v31.new(vector_.X, vector_.Y, vector_.Z, 0, 0, 0, 1)
		v31.new(vector_.X, vector_.Y, vector_.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		v31.lookAt(vector_, n7, vector_4)
		v31.lookAlong(vector_, vector_2, vector_4)
		v31.fromEulerAnglesXYZ(0.81498799073259232, 0.84728299453361833, 0.1774086349829368)
		v31.fromEulerAnglesYXZ(0.81498799073259232, 0.84728299453361833, 0.1774086349829368)
		v31.fromOrientation(0.81498799073259232, 0.84728299453361833, 0.1774086349829368)
		v31.fromAxisAngle(vector_2.Unit, 0.81498799073259232)
		v31.fromRotationBetweenVectors(vector_3, vector_4)
		v31.fromMatrix(vector_, vector_3, vector_4, Vector3.new(0, 0, 1))
		v31.fromEulerAngles(0.81498799073259232, 0.84728299453361833, 0.1774086349829368, xyz)
		v44:Inverse()
		v44:Orthonormalize()
		v44:Lerp(v45, 0.16170987218211641)
		v44:ToWorldSpace(v45)
		v44:ToObjectSpace(v45)
		v44:ToEulerAnglesXYZ()
		v44:ToEulerAnglesYXZ()
		v44:PointToWorldSpace(vector_)
		v44:PointToObjectSpace(vector_)
		v44:VectorToWorldSpace(vector_2)
		v44:VectorToObjectSpace(vector_2)
		v44:ToEulerAngles(xyz)
		v44:GetComponents()
		v44:ToOrientation()
		v44:ToAxisAngle()
		v44:FuzzyEq(v45)
		v44:AngleBetween(v45)
		v29.FromAxis(Enum.Axis.X)
		local vector_5 = Vector3.new(0.06461087, 0.87728274, 0.98588526)
		local vector_6 = Vector3.new(0.9097378, 0.5892761, 0.2382632)
		v29.FromNormalId(Enum.NormalId.Top)
		vector_5:Abs()
		vector_5:Ceil()
		vector_5:Floor()
		vector_5:Sign()
		vector_5:Dot(vector_6)
		vector_5:Cross(vector_6)
		vector_5:Angle(vector_6)
		vector_5:FuzzyEq(vector_6)
		vector_5:Lerp(vector_6, 0.23862436473088477)
		vector_5:Max(vector_6)

		vector_5:Min(vector_6)
		;(Vector2.new(0.31768938899040222, 0.63915246725082397)):Abs()
		;(Vector2.new(0.31768938899040222, 0.63915246725082397)):Ceil()
		;(Vector2.new(0.31768938899040222, 0.63915246725082397)):Floor()
		local vector2 = Vector2.new(0.31768938899040222, 0.63915246725082397)
		local vector22 = Vector2.new(0.82094138860702515, 0.33039948344230652)
		vector2:Sign()
		vector2:Dot(vector22)
		vector2:Cross(vector22)
		vector2:Angle(vector22)
		vector2:FuzzyEq(vector22)
		vector2:Lerp(vector22, 0.34227259606113636)
		vector2:Max(vector22)
		vector2:Min(vector22)
		local v46 = udim(0.76009656396201764, 113)
		local v47 = udim(0.67361077847509154, -5)
		udim2(-0.96666513157279144, 10, -0.19058008134339777, 6):Lerp(udim2(0.1865816087334109, 39, 0.80324479555093742, 102), 0.79054718249380551)
		local left = Enum.NormalId.Top.EnumType.Left
		local enumType = left.EnumType
		enumType:GetEnumItems()
		enumType:FromName(left.Name)
		enumType:FromValue(left.Value)
		local v48 = udim2(0.23720229365342582, 22, 0.085905027871468198, 5)
		local v49 = udim2(0.048931916633880801, 23, 0.043398482589031145, 15)
		local v50 = udim2(0.51279925058027132, 145, 0.51754936400512896, 149)
		local v51 = new3(v48, v49, v49)
		local v52 = new3(v48:Lerp(v50, 0.34633924785845577))
		local tbl4 = {}
		local v53 = new3(v50)
		tbl4[1] = v51
		tbl4[2] = v53
		Frame.Size = udim2(0, 287, 0, 264)
		Path2D:GetControlPoints()
		Path2D:SetControlPoints(tbl4)
		Path2D:GetControlPoint(2)
		Path2D:GetLength()
		Path2D:GetBoundingRect()
		Path2D:GetMaxControlPoints()
		Path2D:GetPositionOnCurve(0.32727050995916795)
		Path2D:GetPositionOnCurveArcLength(0.1794026245540169)
		Path2D:GetTangentOnCurve(0.99087240828359835)
		Path2D:GetTangentOnCurveArcLength(0.74903444093601801)
		Path2D:UpdateControlPoint(1, tbl4[1])
		Path2D:InsertControlPoint(1, v52)
		Path2D:RemoveControlPoint(1)
		local v54 = utf8.char(77, 312, 424102)
		utf8.codepoint(v54, 1, #v54)
		utf8.len(v54)
		utf8.offset(v54, 2)
		utf8.offset(v54, -3)
		local v55, v56, v57 = utf8.codes(v54)
		v55(v56, v57)
		v55(v56, utf8.offset(v54, 1))
		local v58 = utf8.char(97, 790)
		utf8.nfcnormalize(v58)
		utf8.nfdnormalize(v54)
		utf8.graphemes(v58, 1, #v58)()
		n5 = (1 * n5 + 94647748) % 268435456
		n4 = (552563 * n4 + 264196159) % 268435456
	end

	local v42 = coroutine.wrap(fn13)
	local tbl3 = {}
	local n7 = 0

	local function fn14()
		local v43 = nil
		n7 += 1
		n4 = (841225 * n4 + 8391815) % 268435456
		n5 = (1 * n5 + 259681246) % 268435456
	end

	setmetatable(tbl3, { __index = fn14, __newindex = fn14 })
	local ok, result = pcall(fn14)

	if tbl[not ok] then
		fn5(n3 + 619864231, 106)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if tbl[not result] then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	else
		fn5(48356262, 220)
		n3 = bit32.bor(n3, 1198810838) + 4260363264
	end

	local v43 = luraph_runtime1(nil, nil, table.pack(n4, n5))
	local flag = false
	local v44 = luraph_runtime3(nil, nil, table.pack(v40, v26))

	local function fn15()
		n4 = (542491 * n4 + 46957559) % 268435456
		n5 = (1 * n5 + 217733508) % 268435456
	end

	local v45 = luraph_runtime4(nil, nil, table.pack(n5, n4))

	local function fn16()
		n5 = n5 - n5 % 2 + 1
		n4 = (473239 * n4 + 47549277) % 268435456
		n4 = (414495 * n4 + 127700383) % 268435456
	end

	local n8 = 0

	fn2 = function()
		n8 += 1
		n4 = (73991 * n4 + 36716515) % 268435456
		n5 = (1 * n5 + 236461324) % 268435456
		fn2()
	end

	fn3 = function(arg)
		if arg ~= 19998 then
			if arg ~= 19997 then
				if arg == 4288 then
					fn13(arg)
				end
			else
				fn13(arg)
			end

			fn3(arg + 1)

			if arg == 19997 then
				if not v41(v43, v45) then
					n5 = n5 - n5 % 2 + 1
					n4 = (142443 * n4 + 57041191) % 268435456
					return
				end

				fn15()

				if not v40(v43) then
					n5 = n5 - n5 % 2 + 1
					n4 = (945453 * n4 + 233981451) % 268435456
					n4 = (357093 * n4 + 34552565) % 268435456
					return
				end

				if v41(fn16, fn2) then
					n5 = n5 - n5 % 2 + 1
					n4 = (578737 * n4 + 254256965) % 268435456
					n4 = (798245 * n4 + 257678189) % 268435456
					return
				end

				v44()

				if flag then
					n5 = n5 - n5 % 2 + 1
					n4 = (988873 * n4 + 256009849) % 268435456
					n4 = (353417 * n4 + 139638123) % 268435456
					return
				end

				n5 = (1 * n5 + 252731074) % 268435456
				n4 = (578205 * n4 + 137546129) % 268435456
			end

			n5 = (1 * n5 + 184645344) % 268435456
			n4 = (926781 * n4 + 52100555) % 268435456
			return
		end

		v43()
		n5 = (1 * n5 + 25589328) % 268435456
		n4 = (484873 * n4 + 129298801) % 268435456
	end

	coroutine.resume(coroutine.create(fn3), 1)
	ScreenGui:Destroy()
end

fn6(n4, 4)
fn6(n5, 4)
local v40
v40 = n

do
	local n7 = 2081022143
	local n8 = 2027834122

	local v41 = coroutine.wrap(function()
		coroutine.yield(n7)
		coroutine.yield(n8)
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end)

	if fn9(v41(), n7) then
		fn5(n6 - 3036093305, 174)
		n = v40
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(v41(), n8) then
		fn5(n3 + 619864231, 65)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end
end

local n7
n7 = n3 // 176

do
	local thread = coroutine.create(wait)
	coroutine.resume(thread, 0)
	local v41 = coroutine.status(thread)
	fn9("suspended", v41)

	if not nil then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	pcall(coroutine.close, thread)
end

do
	local v41 = nil
	local flag = false

	spawn(function()
		v41 = coroutine.running()
		wait(0)
		flag = true
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end)

	if flag then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	else
	end

	local flag2 = not pcall(coroutine.close, v41)
end

if not nil then
	fn6(132891451, 4)
	n = 160167421
	fn7()
end

do
	local close = coroutine.close

	local function fn13()
		coroutine.yield()
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local v41 = spawn(fn13)
	close(v41)
end

do
	local close = coroutine.close
	local v41 = defer(fn8)
	close(v41)
end

do
	local close = coroutine.close
	local v41 = delay(154, fn8)
	close(v41)
end

local function fn13(arg)
	return (info(arg + 1, "f"))
end

fn = function(arg, ...)
	local flag = not arg

	if tbl[flag] then
		flag = function(...)
			local v41 = fn13

			if not fn9(fn13(1), flag) then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			local v42 = fn9
			local v43 = arg

			if not v42(fn13(2), v43) then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			local v44 = fn13
			local flag2 = not v41

			if not flag2 then
				flag2 = v44(3)
				v43 = xpcall
				v42 = fn9
			end

			if not v42(flag2, v43) then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			if fn9(fn13(4), fn) then
				return ...
			end
			fn6(132891451, 4)
			n = 160167421
			fn7()
			return ...
		end

		local ok, result = xpcall(arg, flag, ...)

		if tbl[not ok] then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		if fn9(result, "error in error handling") then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		return
	end
end

fn(getfenv, -32473)
fn(setfenv, -12812)
fn(getmetatable)
local v41
local v42 = setmetatable
local v43 = table.pack(bit32.band(n6, 4294967295))
local v44 = table.pack(bit32.band(n7, 4294967295))
local v45 = table.pack(bit32.band(v43[1], 65535))
local v46 = table.pack(bit32.rshift(v43[1], 16))
local v47 = table.pack(bit32.band(v44[1], 65535))
v41 = bit32.band(v45[1] * v47[1] + bit32.lshift(bit32.band(v45[1] * bit32.rshift(v44[1], 16) + v46[1] * v47[1], 65535), 16), 4294967295)
fn(v42)
fn(tonumber)
fn(tostring)
fn(rawset)
fn(rawget)
fn(assert)
fn(type)
fn(next)
fn(typeof)
fn(string.gmatch)
fn(string.format)
fn(string.match)
fn(string.find)
fn(string.byte)
fn(string.gsub)
fn(string.sub)
fn(string.rep)
fn(string.char, nil)
fn(string.unpack)
fn(string.pack)
fn(table.concat)
fn(table.insert)
fn(table.clear)
fn(table.create, nil)
fn(table.move)
fn(bit32.bor, nil)
fn(bit32.bxor, nil)
fn(bit32.band, nil)
fn(bit32.bnot)
fn(bit32.lshift)
fn(bit32.rshift)
fn(bit32.rrotate)
fn(bit32.lrotate)
fn(bit32.countlz)
fn(bit32.countrz)
fn(buffer.len)
fn(buffer.fill)
fn(buffer.copy)
fn(buffer.create, nil)
local v48
v48 = bit32.band(v41, n7)
fn(buffer.tostring)
fn(buffer.fromstring)
fn(buffer.readstring)
fn(buffer.writestring)
fn(buffer.readi8)
fn(buffer.readu8)
fn(buffer.readi16)
fn(buffer.readu16)
fn(buffer.readi32)
fn(buffer.readu32)
fn(buffer.readf32)
fn(buffer.readf64)
fn(buffer.writei8)
fn(buffer.writeu8)
local n8
n8 = 471575352
fn(buffer.writei16)
fn(buffer.writeu16)
fn(buffer.writei32)
fn(buffer.writeu32)
fn(buffer.writef32)
fn(buffer.writef64)
fn(buffer.readbits)
fn(buffer.writebits)
fn(coroutine.create)
local n9
n9 = 21024816
fn(coroutine.status)
fn(coroutine.close)
fn(coroutine.resume)
fn(coroutine.wrap)
fn(cancel)
fn(spawn)
fn(defer)
fn(delay)
fn(wait, {})
fn(unpack)
fn(info)
fn(v36)
fn12(513498414, v39, "new")
fn(v39, nil)
fn12(513498414, new, "new")
fn12(513498414, new2, "new")
fn12(513498414, color, "new")
fn12(513498414, rect, "new")
local n10, n11, tbl3, tbl4

do
	local fromAxis = v29.FromAxis
	fn12(513498414, fromAxis, "FromAxis")
	fn(fromAxis, nil)
	local v49 = fromAxis(Enum.Axis.Y)
	local n12 = v48 + n9
	local v50 = v29.FromNormalId(Enum.NormalId.Front)
	local kind = type(v49)
	local kind2 = type(v50)
	fn5(48356262, kind == "vector" and 143 or 1)
	fn5(n12 + 27200244, kind2 == "vector" and 161 or 215)
	local z = v50.Z
	fn6(v49.Y * 2105303073, 4)
	fn6(z * -1 * 2357928243, 4)

	if fn9("vector", kind) then
		fn5(n9 + 27331446, 154)
		n = v40
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9("vector", kind2) then
		fn5(48356262, 30)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	n10 = v49.X == 0 and 111 or 105
	fn5(n12 - 4267767052, n10)
	fn5(n9 + 27331446, v49.Y == 1 and 18 or 26)
	fn5(48356262, v49.Z == 0 and 153 or 104)
	n11 = n9 - n8
	fn5(n12 - 4267767052, v50.X == 0 and 15 or 34)
	fn5(n11 - 3796060498, v50.Y == 0 and 108 or 73)
	fn5(48356262, v50.Z == -1 and 95 or 112)
	fn12(513498414, udim2, "new")
	fn12(513498414, udim, "new")
	v38(utf8, { [3275127054] = 1198511525, [1550820154] = 1824177875, [2841763529] = 17249121 }, 134113654)
	tbl3 = { utf8.nfcnormalize("뤿묍뤶췠졈"):byte(1, -1) }
	tbl4 = { utf8.nfdnormalize("꾤컺퍑췮혴쐊붵"):byte(1, -1) }
	fn5(n12 - 4267767052, tbl4[14])
end

fn5(n11 - 3796060498, tbl4[38])
local v49, v50, v51

do
	local v52 = tbl4[63]
	fn5(48356262, v52)
	local v53 = tbl4[41]
	fn5(48356262, v53)
	fn5(n11 - 3796060498, tbl4[28])
	v49 = tbl4[43]
	v50 = v52
	v51 = v53
end

fn5(48356262, v49)
fn5(48356262, tbl4[10])
fn5(n11 + 498906798, tbl3[10])
fn5(48356262, tbl4[53])
fn5(48356262, tbl4[34])
fn5(n11 + 498906798, tbl4[54])
local v52
v52 = tbl4[27]
fn5(48356262, v52)
local v53
v53 = tbl4[8]
fn5(48356262, v53)
local v54
v54 = tbl4[20]
fn5(n11 - 3796060498, v54)
fn5(48356262, tbl4[61])
local v55, v56, v57, v58, v59, v60, v61

do
	local v62 = tbl3[9]
	fn5(48356262, v62)
	v55 = tbl4[60]
	fn5(n11 - 3796060498, v55)
	fn5(48356262, tbl4[56])
	v56 = tbl4[24]
	fn5(48356262, v56)
	local v63 = tbl4[59]
	local v64 = v50
	v57 = v62
	fn5(n11 + 498906798, v63)
	local v65 = tbl4[7]
	fn5(48356262, v65)
	v58 = tbl3[15]
	fn5(48356262, v58)
	local v66 = tbl3[13]
	v59 = bit32.band(n11, v51)
	v60 = v63
	v61 = v65
	fn5(v59 - 4246611162, v66)
end

local v62
v62 = tbl4[15]
fn5(48356262, v62)
local v63
v63 = tbl4[3]
fn5(48356262, v63)
fn5(v59 - 4246611162, tbl3[14])
fn5(48356262, tbl4[47])
local v64
v64 = tbl4[19]
fn5(48356262, v64)
fn5(v59 + 48356134, tbl4[12])
fn5(48356262, tbl4[31])
local v65
v65 = tbl4[42]
fn5(-4246611034, v65)
fn5(v59 - 4246611162, tbl4[9])
local v66, v67

do
	local v68 = tbl3[8]
	fn5(48356262, v68)
	v66 = tbl4[5]
	fn5(-4246611034, v66)
	fn5(v59 + 48356134, tbl4[55])
	local v69 = tbl4[22]
	v67 = v68
	fn5(48356262, v69)
end

local v68
v68 = tbl4[17]
fn5(48356262, v68)
fn5(v59 - 4246611162, tbl4[35])
fn5(48356262, tbl4[30])
fn5(48356262, tbl4[39])
fn5(48356262, tbl4[32])
fn5(48356262, tbl4[25])
fn5(48356262, tbl4[44])
fn5(48356262, tbl3[3])
fn5(48356262, tbl4[6])
fn5(48356262, tbl3[6])
fn5(48356262, tbl4[11])
fn5(48356262, tbl3[11])
fn5(48356262, tbl3[1])
fn5(48356262, tbl3[12])

do
	local v69 = tbl4[18]
	fn5(48356262, v69)
	fn5(48356262, tbl4[40])
	fn5(48356262, tbl4[46])
	local v70 = v49
	local v71 = v69
end

fn5(48356262, tbl4[48])
fn5(48356262, tbl3[7])
fn5(48356262, tbl4[45])
fn5(48356262, tbl4[29])
fn5(48356262, tbl4[58])
fn5(48356262, tbl4[50])
fn5(48356262, tbl4[57])
fn5(48356262, tbl4[1])
fn5(48356262, tbl4[26])
fn5(48356262, tbl4[62])
fn5(48356262, tbl4[21])
fn5(48356262, tbl3[2])
fn5(48356262, tbl4[16])
fn5(48356262, tbl4[23])
fn5(48356262, tbl3[5])
fn5(48356262, tbl4[49])
fn5(48356262, tbl4[2])
fn5(48356262, tbl4[33])
fn5(48356262, tbl4[13])
fn5(48356262, tbl4[4])
fn5(48356262, tbl4[52])
fn5(48356262, tbl4[51])
fn5(48356262, tbl4[36])
fn5(48356262, tbl3[4])
fn5(48356262, tbl4[37])
fn12(513498414, new3, "new")
fn(new3, nil)
local ScreenGui
ScreenGui = v39("ScreenGui")
local v69

do
	local Frame = v39("Frame")
	Frame.Position = udim2(0, 0, 0, 0)
	Frame.Size = udim2(0, 219, 0, 139)
	Frame.Parent = ScreenGui
	local Path2D = v39("Path2D")
	Path2D.Parent = Frame
	v69 = Path2D
end

do
	local setControlPoints = v69.SetControlPoints
	local tbl5 = {}
	local v70 = new3(udim2(0.5, -1, 0.5, 6), udim2(0, 0, 0, 0), udim2(-0.125, 3, -0.125, 3))
	local v71 = new3(udim2(0.4375, -3, 0, 5), udim2(-0.125, -5, 0, -2), udim2(0, 1, 0.125, -5))
	local v72 = udim2(0, 1, 0.375, -9)
	local v73 = udim2(0, 0, 0, 0)
	tbl5[1] = v70
	tbl5[2] = v71

	do
		local values = table.pack(new3(v72, v73, udim2(0.125, 7, 0, 5)))
		table.move(values, 1, values.n, 3, tbl5)
	end

	setControlPoints(v69, tbl5)
end

do
	local length = v69:GetLength()
	local unpack_ = string.unpack
	local pack = string.pack
	bit32.band(length - length % 1, 536870911)
	fn6(unpack_("<I4", pack("<f", length)), 4)
end

do
	local positionOnCurve = v69:GetPositionOnCurve(0.23076923191547394)
	local unpack_ = string.unpack
	local pack = string.pack
	local scale = positionOnCurve.X.Scale
	bit32.band(scale - scale % 1, 536870911)
	fn6(unpack_(">I4", pack("<f", scale)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local scale2 = positionOnCurve.Y.Scale
	bit32.band(scale2 - scale2 % 1, 536870911)
	fn6(unpack_2("<I4", pack2("<f", scale2)), 4)
end

do
	local positionOnCurve = v69:GetPositionOnCurve(0.875)
	local unpack_ = string.unpack
	local pack = string.pack
	local scale = positionOnCurve.X.Scale
	bit32.band(scale - scale % 1, 536870911)
	fn6(unpack_(">I4", pack("<f", scale)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local scale2 = positionOnCurve.Y.Scale
	bit32.band(scale2 - scale2 % 1, 536870911)
	fn6(unpack_2("<I4", pack2("<f", scale2)), 4)
end

local v70

do
	local tangentOnCurve = v69:GetTangentOnCurve(0.78571426868438721)
	local unpack_ = string.unpack
	local pack = string.pack
	local x = tangentOnCurve.X
	bit32.band(x - x % 1, 536870911)
	v70 = v52
	fn6(unpack_(">I4", pack(">f", x)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local y = tangentOnCurve.Y
	bit32.band(y - y % 1, 536870911)
	fn6(unpack_2("<I4", pack2("<f", y)), 4)
end

do
	local tangentOnCurve = v69:GetTangentOnCurve(0.3333333432674408)
	local unpack_ = string.unpack
	local pack = string.pack
	local x = tangentOnCurve.X
	bit32.band(x - x % 1, 536870911)
	fn6(unpack_(">I4", pack("<f", x)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local y = tangentOnCurve.Y
	bit32.band(y - y % 1, 536870911)
	fn6(unpack_2(">I4", pack2(">f", y)), 4)
end

do
	local tangentOnCurve = v69:GetTangentOnCurve(0.46153846383094788)
	local unpack_ = string.unpack
	local pack = string.pack
	local x = tangentOnCurve.X
	bit32.band(x - x % 1, 536870911)
	fn6(unpack_(">I4", pack("<f", x)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local y = tangentOnCurve.Y
	bit32.band(y - y % 1, 536870911)
	fn6(unpack_2(">I4", pack2(">f", y)), 4)
end

do
	local positionOnCurveArcLength = v69:GetPositionOnCurveArcLength(0.9375)
	local unpack_ = string.unpack
	local pack = string.pack
	local scale = positionOnCurveArcLength.X.Scale
	bit32.band(scale - scale % 1, 536870911)
	fn6(unpack_(">I4", pack(">f", scale)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local scale2 = positionOnCurveArcLength.Y.Scale
	bit32.band(scale2 - scale2 % 1, 536870911)
	fn6(unpack_2("<I4", pack2("<f", scale2)), 4)
end

do
	local positionOnCurveArcLength = v69:GetPositionOnCurveArcLength(0.4166666567325592)
	local unpack_ = string.unpack
	local pack = string.pack
	local scale = positionOnCurveArcLength.X.Scale
	bit32.band(scale - scale % 1, 536870911)
	fn6(unpack_("<I4", pack(">f", scale)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local scale2 = positionOnCurveArcLength.Y.Scale
	bit32.band(scale2 - scale2 % 1, 536870911)
	fn6(unpack_2("<I4", pack2("<f", scale2)), 4)
end

local n12

do
	local positionOnCurveArcLength = v69:GetPositionOnCurveArcLength(0.625)
	local unpack_ = string.unpack
	local pack = string.pack
	local scale = positionOnCurveArcLength.X.Scale
	n12 = v70 + v54
	bit32.band(scale - scale % 1, 536870911)
	fn6(unpack_("<I4", pack("<f", scale)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local scale2 = positionOnCurveArcLength.Y.Scale
	bit32.band(scale2 - scale2 % 1, 536870911)
	fn6(unpack_2("<I4", pack2(">f", scale2)), 4)
end

local n13

do
	local tangentOnCurveArcLength = v69:GetTangentOnCurveArcLength(0.23076923191547394)
	local unpack_ = string.unpack
	local v71 = table.pack(bit32.band(v57, 4294967295))
	local v72 = table.pack(bit32.band(v71[1], 65535))
	local v73 = bit32.band(65535 * v72[1] + bit32.lshift(bit32.band(65535 * bit32.rshift(v71[1], 16) + 65535 * v72[1], 65535), 16), 4294967295)
	local v74 = table.pack(bit32.band(bit32.bor(471575425, v57), 4294967295))
	local v75 = table.pack(bit32.band(v74[1], 65535))
	local n14 = 3823391871 + v73 + bit32.band(2 * v75[1] + bit32.lshift(bit32.band(2 * bit32.rshift(v74[1], 16) + 0 * v75[1], 65535), 16), 4294967295)
	local v76 = table.pack(bit32.band(n10, 4294967295))
	local v77 = table.pack(bit32.band(v76[1], 65535))
	local v78 = bit32.band(56091 * v77[1] + bit32.lshift(bit32.band(56091 * bit32.rshift(v76[1], 16) + 33262 * v77[1], 65535), 16), 4294967295)
	local v79 = table.pack(bit32.band(bit32.bnot(n10), 4294967295))
	local v80 = table.pack(bit32.band(v79[1], 65535))
	n13 = n14 + 2179914523 + v78 + bit32.band(56091 * v80[1] + bit32.lshift(bit32.band(56091 * bit32.rshift(v79[1], 16) + 33262 * v80[1], 65535), 16), 4294967295)
	local pack = string.pack
	local x = tangentOnCurveArcLength.X
	bit32.band(x - x % 1, 536870911)
	fn6(unpack_(">I4", pack(">f", x)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local y = tangentOnCurveArcLength.Y
	bit32.band(y - y % 1, 536870911)
	fn6(unpack_2(">I4", pack2("<f", y)), 4)
end

local n14

do
	local tangentOnCurveArcLength = v69:GetTangentOnCurveArcLength(0.83333331346511841)
	local unpack_ = string.unpack
	local pack = string.pack
	local x = tangentOnCurveArcLength.X
	bit32.band(x - x % 1, 536870911)
	n14 = v53 // v55
	fn6(unpack_("<I4", pack(">f", x)), 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local y = tangentOnCurveArcLength.Y
	bit32.band(y - y % 1, 536870911)
	fn6(unpack_2(">I4", pack2(">f", y)), 4)
end

ScreenGui:Destroy()
v38(math, { [4037819469] = 231057979, [1739845119] = 360566320, [1728930129] = 1712938505 }, 134113654)

v38(v37, {
	[563340364] = 2018829887,
	[1249812499] = 848476404,
	[3569266548] = 282592110,
	[3576434784] = 2051370136,
	[2124572879] = 479803336,
}, 134113654)

v38(v27, { [1060672026] = 704135565, [2390163983] = 1286623458 }, 134113654)
local v71
v71 = game
local fn14
local v72 = workspace

fn14 = function(arg, arg2, arg3)
	local state = 1
	local v73, n15, thread, v74, name, parent, parent2, name2, n16, v75, flag, n17, attributeChanged, flag2, flag3, flag4

	while true do
		if state == 1 then
			v73 = arg
			n15 = arg2
			thread = arg3
			local v76 = nil
			local v77 = nil
			v74 = nil
			state = 2
		elseif state == 2 then
			local kind = type(v73)
			name = fn9
			fn9("userdata", kind)

			if nil then
				state = 3
			else
				state = 32
			end
		elseif state == 3 then
			local kind = typeof(v73)
			fn9("Instance", kind)

			if nil then
				state = 4
			else
				state = 34
			end
		elseif state == 4 then
			parent = v73.Parent
			parent2 = v73.Parent

			if tbl[not parent] then
				state = 5
			else
				state = 60
			end
		elseif state == 5 then
			name2 = parent
			v74 = parent2
			state = 6
		elseif state == 6 then
			fn9(name2, v74)

			if nil then
				state = 7
			else
				state = 26
			end
		elseif state == 7 then
			if name then
				state = 60
			else
				state = 8
			end
		elseif state == 8 then
			if nil then
				state = 9
			else
				state = 94
			end
		elseif state == 9 then
			if nil <= 22 then
				state = 35
			else
				state = 10
			end
		elseif state == 10 then
			if nil <= 33 then
				state = 22
			else
				state = 11
			end
		elseif state == 11 then
			if nil <= 39 then
				state = 17
			else
				state = 12
			end
		elseif state == 12 then
			if nil <= 42 then
				state = 15
			else
				state = 13
			end
		elseif state == 13 then
			if nil <= 43 then
				state = 92
			else
				state = 14
			end
		elseif state == 14 then
			if nil <= 44 then
				state = 62
			else
				state = 75
			end
		elseif state == 15 then
			if nil <= 40 then
				state = 2
			else
				state = 16
			end
		elseif state == 16 then
			if nil <= 41 then
				state = 68
			else
				state = 92
			end
		elseif state == 17 then
			if nil <= 36 then
				state = 20
			else
				state = 18
			end
		elseif state == 18 then
			if nil <= 37 then
				state = 67
			else
				state = 19
			end
		elseif state == 19 then
			if nil <= 38 then
				state = 3
			else
				state = 61
			end
		elseif state == 20 then
			if nil <= 34 then
				state = 63
			else
				state = 21
			end
		elseif state == 21 then
			if nil <= 35 then
				state = 98
			else
				state = 90
			end
		elseif state == 22 then
			if nil <= 27 then
				state = 29
			else
				state = 23
			end
		elseif state == 23 then
			if nil <= 30 then
				state = 27
			else
				state = 24
			end
		elseif state == 24 then
			if nil <= 31 then
				state = 74
			else
				state = 25
			end
		elseif state == 25 then
			if nil <= 32 then
				state = 65
			else
				state = 26
			end
		elseif state == 26 then
			fn6(132891451, 4)
			n = 160167421
			fn7()
			state = 7
		elseif state == 27 then
			if nil <= 28 then
				state = 73
			else
				state = 28
			end
		elseif state == 28 then
			if nil <= 29 then
				state = 94
			else
				state = 96
			end
		elseif state == 29 then
			if nil <= 24 then
				state = 33
			else
				state = 30
			end
		elseif state == 30 then
			if nil <= 25 then
				state = 64
			else
				state = 31
			end
		elseif state == 31 then
			if nil <= 26 then
				state = 101
			else
				state = 32
			end
		elseif state == 32 then
			local v76 = fn6
			local v77 = table.pack(bit32.band(n16, 4294967295))
			local v78 = table.pack(bit32.band(n15, 4294967295))
			local v79 = table.pack(bit32.band(v77[1], 65535))
			local v80 = table.pack(bit32.rshift(v77[1], 16))
			local v81 = table.pack(bit32.band(v78[1], 65535))
			local v82 = bit32.band(v79[1] * v81[1] + bit32.lshift(bit32.band(v79[1] * bit32.rshift(v78[1], 16) + v80[1] * v81[1], 65535), 16), 4294967295)
			v76(132891451, 4)
			n = 160167421
			fn7()
			n16 = v82 - 1922006908
			state = 3
		elseif state == 33 then
			if nil <= 23 then
				state = 102
			else
				state = 34
			end
		elseif state == 34 then
			fn6(132891451, 4)
			n = 160167421
			fn7()
			state = 4
		elseif state == 35 then
			if nil <= 10 then
				state = 50
			else
				state = 36
			end
		elseif state == 36 then
			if nil <= 16 then
				state = 45
			else
				state = 37
			end
		elseif state == 37 then
			if nil <= 19 then
				state = 40
			else
				state = 38
			end
		elseif state == 38 then
			if nil <= 20 then
				state = 71
			else
				state = 39
			end
		elseif state == 39 then
			if nil <= 21 then
				state = 88
			else
				state = 70
			end
		elseif state == 40 then
			if nil <= 17 then
				state = 80
			else
				state = 41
			end
		elseif state == 41 then
			if nil <= 18 then
				state = 42
			else
				state = 90
			end
		else
			local n18

			if state == 42 then
				local wait2 = (nil).Wait
				fn12(513498414, wait2, "Wait")

				local function fn15()
					return (wait2(v75))
				end

				thread = coroutine.create(fn15)
				local v76
				v76, name = coroutine.resume(thread)
				local v77 = tbl[not v76]
				flag = not v77
				n18 = nil // 9

				if v77 then
					state = 44
				else
					state = 43
				end
			elseif state == 43 then
				state = 86
			elseif state == 44 then
				state = 88
			elseif state == 45 then
				if nil <= 13 then
					state = 48
				else
					state = 46
				end
			elseif state == 46 then
				if nil <= 14 then
					state = 82
				else
					state = 47
				end
			elseif state == 47 then
				if nil <= 15 then
					state = 83
				else
					state = 60
				end
			elseif state == 48 then
				if nil <= 11 then
					state = 7
				else
					state = 49
				end
			elseif state == 49 then
				if nil <= 12 then
					state = 99
				else
					state = 76
				end
			elseif state == 50 then
				if nil <= 4 then
					state = 56
				else
					state = 51
				end
			elseif state == 51 then
				if nil <= 7 then
					state = 54
				else
					state = 52
				end
			elseif state == 52 then
				if nil <= 8 then
					state = 79
				else
					state = 53
				end
			elseif state == 53 then
				if nil <= 9 then
					state = 99
				else
					state = 69
				end
			elseif state == 54 then
				if nil <= 5 then
					state = 72
				else
					state = 55
				end
			elseif state == 55 then
				if nil <= 6 then
					state = 81
				else
					state = 4
				end
			elseif state == 56 then
				if nil <= 1 then
					state = 59
				else
					state = 57
				end
			elseif state == 57 then
				if nil <= 2 then
					state = 96
				else
					state = 58
				end
			elseif state == 58 then
				if nil <= 3 then
					state = 100
				else
					state = 66
				end
			elseif state == 59 then
				if nil <= 0 then
					state = 103
				else
					state = 6
				end
			elseif state == 60 then
				name = v73.Name
				name2 = v73.Name
				local kind = type(name)
				fn9("string", kind)

				if nil then
					state = 62
				else
					state = 61
				end
			elseif state == 61 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 62
			elseif state == 62 then
				fn9(name, name2)

				if nil then
					state = 64
				else
					state = 63
				end
			elseif state == 63 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				n15 = 188478511
				n17 = -1810466977
				state = 64
			elseif state == 64 then
				fn9(#name, #name2)

				if nil then
					state = 66
				else
					state = 65
				end
			elseif state == 65 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 66
			elseif state == 66 then
				fn9(tostring(v73), name)

				if nil then
					state = 68
				else
					state = 67
				end
			elseif state == 67 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 68
			elseif state == 68 then
				fn9(thread, v73.ClassName)

				if nil then
					state = 70
				else
					state = 69
				end
			elseif state == 69 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 70
			elseif state == 70 then
				attributeChanged = v73.AttributeChanged
				thread = v73.AttributeChanged
				fn9(attributeChanged, thread)

				if nil then
					state = 71
				else
					state = 72
				end
			elseif state == 71 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 72
			elseif state == 72 then
				if nil then
					state = 74
				else
					state = 73
				end
			elseif state == 73 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				n16 = 732764914
				state = 74
			elseif state == 74 then
				local connect = attributeChanged.Connect
				local connect2 = attributeChanged.Connect
				fn12(n17 + 2323965391, connect, "Connect")
				fn12(n16 + 4075700796, connect2, "Connect")
				fn9(connect, connect2)

				if nil then
					state = 75
				else
					state = 76
				end
			elseif state == 75 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 76
			elseif state == 76 then
				local flag5 = false
				local ancestryChanged = v73.AncestryChanged
				local v76 = ancestryChanged
				local connect = ancestryChanged.Connect
				local n19 = n16 - 404835056

				local function fn15()
					flag5 = true
					n19 = 1637026123
				end

				n19 = 511683661
				thread = connect(v76, fn15)

				if nil then
					state = 78
				else
					state = 77
				end
			elseif state == 77 then
				state = 80
			elseif state == 78 then
				state = 79
			elseif state == 79 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 80
			elseif state == 80 then
				if nil then
					state = 82
				else
					state = 81
				end
			elseif state == 81 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 82
			elseif state == 82 then
				local disconnect = thread.Disconnect
				fn12(513498414, disconnect, "Disconnect")
				fn(disconnect, nil)
				disconnect(thread)

				if nil then
					state = 83
				else
					state = 84
				end
			elseif state == 83 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 84
			elseif state == 84 then
				local wait2 = attributeChanged.Wait
				fn12(513498414, wait2, "Wait")

				local function fn15()
					return (wait2(attributeChanged))
				end

				thread = coroutine.create(fn15)
				local v76
				v76, name = coroutine.resume(thread)
				local v77 = tbl[not v76]
				flag = not v77
				n18 = n17 // 9

				if v77 then
					state = 87
				else
					state = 85
				end
			elseif state == 85 then
				state = 86
			elseif state == 86 then
				flag2 = flag
				state = 89
			elseif state == 87 then
				state = 88
			elseif state == 88 then
				flag2 = tbl[not name]
				state = 89
			elseif state == 89 then
				if flag2 then
					state = 91
				else
					state = 90
				end
			elseif state == 90 then
				local v76 = coroutine.status(thread)
				flag2 = not fn9("suspended", v76)
				state = 91
			elseif state == 91 then
				if flag2 then
					state = 103
				else
					state = 92
				end
			elseif state == 92 then
				local ok
				ok, name = pcall(coroutine.close, thread)
				local v76 = tbl[not ok]
				flag3 = not v76

				if v76 then
					state = 94
				else
					state = 93
				end
			elseif state == 93 then
				flag4 = flag3
				state = 95
			elseif state == 94 then
				flag4 = not tbl[not name]
				state = 95
			elseif state == 95 then
				if flag4 then
					state = 97
				else
					state = 96
				end
			elseif state == 96 then
				local v76 = coroutine.status(thread)
				flag4 = not fn9("dead", v76)
				state = 97
			elseif state == 97 then
				if flag4 then
					state = 98
				else
					state = 99
				end
			elseif state == 98 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 99
			elseif state == 99 then
				local v76 = getmetatable(v73)
				fn9("The metatable is locked", v76)

				if nil then
					state = 101
				else
					state = 100
				end
			elseif state == 100 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 101
			elseif state == 101 then
				state = 102
			elseif state == 102 then
				return
			elseif state == 103 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				v74[88] = 88
				error("devirt: bit32.band failed: invalid literal for int() with base 10: b'FuzzyEq' (at 26:1022)")
			end
		end
	end
end

fn14(v71, 188478511, "DataModel")
fn14(v72, 188478511, "Workspace")

if fn9(v71, v72.Parent) then
	fn5(48356262, 230)
	n = v40
else
	fn6(132891451, 4)
	n = 160167421
	fn7()
end

local v73

do
	local Folder = v39("Folder")
	fn14(Folder, 188478511, "Folder")
	local ok, result = pcall(Folder.QueryDescendants, UDim2.new(-1.7407736778259277, 42, -1.5675561428070068, -142), 75524072)
	local flag = not ok

	if not tbl[flag] then
		fn6(fn11(500146443, result), 4)
	end

	local v74 = n

	if tbl[flag] then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	else
		fn5(48356262, 71)
		n13 = bit32.bxor(bit32.bxor(n13, 132), 132)
		n = v74
	end

	local children, v75, v76 = Folder:GetChildren()
	local v77 = bit32.bor(n12, v56)
	local v78 = table.pack(b_1())

	if v78[1] then
		repeat
			fn6(132891451, 4)
			n = 160167421
			fn7()
			local v79 = table.pack(b_1())
		until not v79[1]
	end

	Folder:Destroy()
	local v79 = Folder
	local v80 = n
	local Folder2 = v39("Folder", v79)
	fn14(Folder2, 188478511, "Folder")
	local parent = Folder2.Parent
	v73 = bit32.bor(n14, v60)

	if fn9(v79, parent) then
		fn5(48356262, 27)
		n = v80
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(Folder2.Parent, Folder2.Parent) then
		fn5(48356262, 154)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local waitForChild = v79.WaitForChild
	fn12(513498414, waitForChild, "WaitForChild")
	fn(waitForChild, nil)
	local name = tostring(1995315004)
	Folder2.Name = name
	local v81 = waitForChild(v79, name)

	if fn9(Folder2, v81) then
		fn5(48356262, 107)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	v79:Destroy()
	Folder2:Destroy()
	local flag2 = not Folder2.Parent
	local v82 = bit32.bor(v77, v61)

	if tbl[flag2] then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	else
		fn5(48356262, 135)
	end

	if tbl[not pcall(function()
		Folder2.Parent = v79
	end)] then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	else
		fn5(48356262, 38)
	end

	n = v80
	local HttpService = v71:GetService("HttpService")
	fn14(HttpService, 188478511, "HttpService")
	local v83 = n
	local v84

	if fn9(v71, HttpService.Parent) then
		fn5(48356262, 173)
		n = v83
		v84 = v83
	else
		v84 = v83
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local RunService = v71:GetService("RunService")
	fn14(RunService, 188478511, "RunService")

	if fn9(v71, RunService.Parent) then
		fn5(48356262, 236)
		n = v84
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local n15 = v82 * v58
	fn12(513498414, RunService.IsStudio, "IsStudio")
	fn12(513498414, RunService.IsClient, "IsClient")
	fn12(513498414, RunService.IsServer, "IsServer")
	fn(RunService.IsStudio)
	fn(RunService.IsClient)
	fn(RunService.IsServer)
	RunService:IsServer()

	if nil then
		local StarterPlayer = v71:GetService("StarterPlayer")
		fn14(StarterPlayer, 188478511, "StarterPlayer")
		local v85 = bit32.bxor(n13, 236)
		fn9(v71, StarterPlayer.Parent)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		local children2, v86, v87 = StarterPlayer:GetChildren()
		local n16 = 0
		local v88 = table.pack(b_1())

		if v88[1] then
			repeat
				n16 += 1
				local v89 = table.pack(b_1())
			until not v89[1]
		end

		if nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		n13 = bit32.bxor(v85, 236)
	end

	if tbl[not pcall(v71.GetChildren)] then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	else
		fn5(48356262, 177)
		n = v84
	end
end

local v74, n15, v75, n16, v76

do
	local v77 = Enum
	local n17 = v73 * v62
	local v78 = n

	if fn9(type(v77), "userdata") then
		fn5(48356262, 46)
		n = v78
		v74 = v78
	else
		v74 = v78
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(typeof(v77), "Enums") then
		fn5(48356262, 242)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local v79 = getmetatable(v77)

	if fn9("The metatable is locked", v79) then
		fn5(48356262, 237)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local block = v77.PartType.Wedge.EnumType.Block

	if fn9(type(block), "userdata") then
		fn5(48356262, 110)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(typeof(block), "EnumItem") then
		fn5(48356262, 80)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
		n17 = v63 + 21816
	end

	local v80 = getmetatable(block)

	if fn9("The metatable is locked", v80) then
		fn5(48356262, 2)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	fn12(513498414, block.IsA, "IsA")
	fn(block.IsA)
	local name = block.Name
	local value = block.Value
	n15 = 69113

	if fn9(type(name), "string") then
		fn5(48356262, 134)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local v81 = fn9(type(value), "number")
	local v82 = bit32.bxor(n13, 132)

	if v81 then
		fn5(48356262, 28)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local enumType = block.EnumType

	if fn9(block, enumType[name]) then
		fn5(48356262, 140)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(type(enumType), "userdata") then
		fn5(48356262, 37)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(typeof(enumType), "Enum") then
		fn5(48356262, 18)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local v83 = getmetatable(enumType)

	if fn9("The metatable is locked", v83) then
		fn5(48356262, 117)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	fn12(513498414, enumType.FromName, "FromName")
	fn12(513498414, enumType.FromValue, "FromValue")
	v75 = bit32.bor(n17, v64)
	fn(enumType.FromName)
	fn(enumType.FromValue)
	local v84 = enumType:FromName(name)

	if fn9(block, v84) then
		fn5(48356262, 159)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local v85 = enumType:FromValue(value)

	if fn9(block, v85) then
		fn5(48356262, 136)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local new4 = v32.new
	fn12(513498414, new4, "new")
	fn(new4, {})
	local v86 = new4(1584536020)
	local kind = type(v86)
	local n18 = 98
	local n19 = bit32.bxor(v82, 143) + 4258985330
	local v87 = table.pack(bit32.band(n10, 4294967295))
	local v88 = table.pack(bit32.band(v87[1], 65535))
	local v89 = bit32.band(62834 * v88[1] + bit32.lshift(bit32.band(62834 * bit32.rshift(v87[1], 16) + 64986 * v88[1], 65535), 16), 4294967295)
	local v90 = table.pack(bit32.band(bit32.bnot(n10), 4294967295))
	local v91 = table.pack(bit32.band(v90[1], 65535))
	n16 = n19 + v89 + bit32.band(62834 * v91[1] + bit32.lshift(bit32.band(62834 * bit32.rshift(v90[1], 16) + 64986 * v91[1], 65535), 16), 4294967295)
	fn9(kind, "userdata")

	if nil then
		fn5(48356262, n18)
		n = v74
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(typeof(v86), "Random") then
		fn5(48356262, 72)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	fn12(513498414, v86.NextUnitVector, "NextUnitVector")
	fn12(513498414, v86.NextInteger, "NextInteger")
	fn12(513498414, v86.NextNumber, "NextNumber")
	fn12(513498414, v86.Shuffle, "Shuffle")
	fn12(513498414, v86.Clone, "Clone")
	v76 = new4(1893939534)
end

fn6(v76:NextInteger(75, 468), 4)
fn6(v76:NextInteger(438, 847), 4)
local clone
clone = v76:Clone()

do
	local unpack_ = string.unpack
	local pack = string.pack
	local v77 = clone:NextNumber()
	bit32.band(v77 - v77 % 1, 536870911)
	fn6(unpack_("<I4", pack(">f", v77)), 4)
end

fn6(clone:NextInteger(937, 964), 4)
fn6(v76:NextInteger(883, 1829), 4)
local v77

do
	local unpack_ = string.unpack
	local pack = string.pack
	local v78 = v76:NextNumber()
	bit32.band(v78 - v78 % 1, 536870911)
	local v79 = unpack_(">I4", pack("<f", v78))
	v77 = bit32.bxor(n16, 175)
	fn6(v79, 4)
end

fn6(clone:NextInteger(871, 1657), 4)

do
	local unpack_ = string.unpack
	local pack = string.pack
	local v78 = clone:NextNumber()
	bit32.band(v78 - v78 % 1, 536870911)
	fn6(unpack_("<I4", pack(">f", v78)), 4)
end

do
	local unpack_ = string.unpack
	local pack = string.pack
	local v78 = clone:NextNumber()
	bit32.band(v78 - v78 % 1, 536870911)
	fn6(unpack_(">I4", pack(">f", v78)), 4)
end

do
	local clone2 = v76:Clone()
	local unpack_ = string.unpack
	local pack = string.pack
	local v78 = clone:NextNumber()
	bit32.band(v78 - v78 % 1, 536870911)
	local v79 = unpack_(">I4", pack(">f", v78))
	local v80 = bit32.bor(v75, v67)
	fn6(v79, 4)
	local unpack_2 = string.unpack
	local pack2 = string.pack
	local v81 = clone2:NextNumber()
	bit32.band(v81 - v81 % 1, 536870911)
	fn6(unpack_2("<I4", pack2(">f", v81)), 4)
end

do
	local unpack_ = string.unpack
	local pack = string.pack
	local v78 = clone:NextNumber()
	bit32.band(v78 - v78 % 1, 536870911)
	fn6(unpack_("<I4", pack("<f", v78)), 4)
end

local n17

do
	local n18 = 40

	local tbl5 = {
		[1433250657] = 40,
		[65673899] = 40,
		[201969048] = 10,
		[4258425723] = 40,
		[1851323751] = 20,
		[1785358471] = 40,
		[2745256498] = 40,
		[1100865733] = 40,
		[552963487] = 20,
		[3085612159] = 10,
		[177794054] = 40,
		[3410580392] = n18,
		[4044573931] = 10,
		[2040232487] = 10,
		[2192240511] = 10,
		[1544915864] = 10,
		[4066772667] = n18,
		[419860109] = n18,
		[4092020813] = n18,
		[2910296487] = n18,
		[3263052793] = n18,
		[3575717172] = 10,
		[2263798947] = 10,
		[2740284763] = n18,
		[1213003131] = n18,
		[2805714417] = 10,
		[1088756010] = 10,
		[3169496954] = 10,
		[2984952513] = 10,
		[4164857737] = n18,
		[292715581] = n18,
		[1140742247] = n18,
	}

	local env = getfenv()
	local tbl6 = {}
	n17 = n15 // v65 - v66
	local tbl7 = {}
	local n19 = 0
	local tbl8 = { 1, 3, 0, v, nil }

	while true do
		local v78 = tbl8[1]
		local v79 = tbl8[2]
		local n20 = tbl8[3] + v78
		local flag = v78 <= 0
		tbl8[3] = n20

		if n20 <= v79 then
			type(env)

			if not nil then
				if not nil then
					tbl6[env] = true
					local n21 = 0

					for k in env, nil, nil do
						n21 += 1
						local kind = type(k)

						if fn9("string", kind) then
							if #k < 20 then
								local v80 = fn11(500146443, k)

								if not tbl7[v80] then
									n19 += tbl5[v80] or 0
									tbl7[v80] = true
									if n21 > 50 then
										break
									end
									continue
								end
							end
						end

						if n21 > 50 then
							break
						end
					end

					local v80 = n19
					local v81 = getmetatable(env)
					local flag2 = type(v81) == "table"
					local v82, value

					if flag2 then
						v82 = v80
						value = rawget(v81, "__index")
					else
						v82 = v80
						value = flag2
					end

					if value then
						local v83 = v82
						env = value
						n19 = v83
					else
						n19 = v82
						env = nil
					end

					continue
				end
			end

			break
		else
			break
		end
	end

	local v78 = tbl8[4]
	fn5(48356262, n19 < n18 and 131 or 254)

	if nil then
		fn6(132891451, 4)
		n = 160167421
		fn7()
		v77 = bit32.bxor(bit32.bxor(v77, 225), 225)
	end

	local ok, result = pcall(assert, false)

	if ok or not result or type(result) ~= "string" then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local ok2, result2 = pcall(function(B,...)(...)[...]=nil;end)
	local ok3, result3 = pcall(function(B,...)return(...)[...];end)
	local ok4, result4 = pcall(function(B,...)return(...)();end)

	if ok2 or ok3 or ok4 then
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	local function fn15(arg, arg2, arg3)
		local state = 1
		local v79, v80, v81, n20, n21, str, flag, flag2, v82, v83, v84, n22, v85, v86, n23, flag3, flag4, flag5, flag6, v87

		while true do
			if state == 1 then
				v79 = arg
				v80 = arg2
				v81 = arg3
				state = 2
			elseif state == 2 then
				n20, n21, str = string.find(v79, "[%:][^%w%W]-(%d%d*)[%:\n\r][^%d%D]?")
				flag = not n20

				if n20 then
					state = 4
				else
					state = 3
				end
			elseif state == 3 then
				flag2 = flag
				state = 5
			elseif state == 4 then
				flag2 = not n21
				state = 5
			elseif state == 5 then
				if flag2 then
					state = 6
				else
					state = 7
				end
			elseif state == 6 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 7
			elseif state == 7 then
				fn6(n20, 2)
				v83 += v82
				fn6(n21, 2)
				v84 = string.match(v79, "[:]([%d]+)[:\n\r][^%c%C]?")
				flag2 = fn6

				if str then
					state = 9
				else
					state = 8
				end
			elseif state == 8 then
				str = v84
				state = 58
			elseif state == 9 then
				n22 = v84
				state = 10
			elseif state == 10 then
				flag2(str + 0, 2)
				str = fn6

				if n22 then
					state = 11
				else
					state = 52
				end
			elseif state == 11 then
				str(n22 + 0, 2)
				local v88 = string.gmatch(v79, "%:[^%a%A]*(%d+)[^%s%S]*[\r%:\n][^%l%L]?")
				str = v88()
				fn9(v88(), nil)

				if nil then
					state = 12
				else
					state = 48
				end
			elseif state == 12 then
				v85 = fn6

				if str then
					state = 14
				else
					state = 13
				end
			elseif state == 13 then
				str = v85
				state = 35
			elseif state == 14 then
				flag2 = v85
				state = 15
			elseif state == 15 then
				flag2(str + 0, 2)
				str = string.sub(v79, n20 + 1, n21 - 1)
				flag2 = string.char(string.byte(v79, n20 + 1, n21 - 1))
				n22 = string.byte(v79, n20 + 1, n20 + 1)
				state = 16
			elseif state == 16 then
				v82 += v80
				fn6(str + 0, 2)
				fn6(flag2 + 0, 2)
				local v88 = fn5
				fn5(48356262, n22)
				local tbl9 = { v86, 1, n21 - 1 + 0, n20 + 1 - 1, nil }
				n20 = 0
				v86 = tbl9
				n21 = v88
				state = 17
			elseif state == 17 then
				local v88 = v86[2]
				local v89 = v86[3]
				n23 = v86[4] + v88
				flag3 = v88 <= 0
				flag4 = not flag3
				flag5 = n23 >= v89
				flag6 = n23 <= v89

				if flag3 then
					state = 19
				else
					state = 18
				end
			elseif state == 18 then
				flag5 = flag3

				if flag4 then
					state = 21
				else
					state = 20
				end
			elseif state == 19 then
				if flag4 then
					state = 21
				else
					state = 20
				end
			elseif state == 20 then
				flag6 = flag4

				if flag5 then
					state = 23
				else
					state = 22
				end
			elseif state == 21 then
				if flag5 then
					state = 23
				else
					state = 22
				end
			elseif state == 22 then
				flag5 = flag6
				state = 23
			elseif state == 23 then
				v86[4] = n23

				if flag5 then
					state = 69
				else
					state = 24
				end
			elseif state == 24 then
				v86 = v86[1]
				state = 25
			elseif state == 25 then
				fn6(n20, 2)
				v87 = nil
				local n24 = 0
				local n25 = v82 - 4151960069

				local function fn16(arg4)
					v87 = arg4
					n24 += 1
				end

				n25 = 18572033
				local v88
				v88, n20 = string.gsub(v79, ":([0-9][0-9]*)[^%x%X]-[\r:\n][^%s%S]?", fn16, 1)
				fn9(n24, 1)

				if nil then
					state = 59
				else
					state = 26
				end
			elseif state == 26 then
				state = 27
			elseif state == 27 then
				fn6(132891451, 4)
				n = 160167421
				fn7()

				if n21 then
					state = 60
				else
					state = 28
				end
			elseif state == 28 then
				if nil then
					state = 29
				else
					state = 61
				end
			elseif state == 29 then
				if nil <= 12 then
					state = 44
				else
					state = 30
				end
			elseif state == 30 then
				if nil <= 19 then
					state = 38
				else
					state = 31
				end
			elseif state == 31 then
				if nil <= 22 then
					state = 36
				else
					state = 32
				end
			elseif state == 32 then
				if nil <= 24 then
					state = 34
				else
					state = 33
				end
			elseif state == 33 then
				if nil <= 25 then
					state = 4
				else
					state = 5
				end
			elseif state == 34 then
				if nil <= 23 then
					state = 35
				else
					state = 12
				end
			elseif state == 35 then
				flag2 = str
				str = 0
				state = 15
			elseif state == 36 then
				if nil <= 20 then
					state = 2
				else
					state = 37
				end
			elseif state == 37 then
				if nil <= 21 then
					state = 62
				else
					state = 15
				end
			elseif state == 38 then
				if nil <= 15 then
					state = 42
				else
					state = 39
				end
			elseif state == 39 then
				if nil <= 17 then
					state = 41
				else
					state = 40
				end
			elseif state == 40 then
				if nil <= 18 then
					state = 61
				else
					state = 66
				end
			elseif state == 41 then
				if nil <= 16 then
					state = 17
				else
					state = 67
				end
			elseif state == 42 then
				if nil <= 13 then
					state = 7
				else
					state = 43
				end
			elseif state == 43 then
				if nil <= 14 then
					state = 6
				else
					state = 16
				end
			elseif state == 44 then
				if nil <= 5 then
					state = 53
				else
					state = 45
				end
			elseif state == 45 then
				if nil <= 8 then
					state = 50
				else
					state = 46
				end
			elseif state == 46 then
				if nil <= 10 then
					state = 49
				else
					state = 47
				end
			elseif state == 47 then
				if nil <= 11 then
					state = 60
				else
					state = 48
				end
			elseif state == 48 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 12
			elseif state == 49 then
				if nil <= 9 then
					state = 10
				else
					state = 24
				end
			elseif state == 50 then
				if nil <= 6 then
					state = 27
				else
					state = 51
				end
			elseif state == 51 then
				if nil <= 7 then
					state = 52
				else
					state = 25
				end
			elseif state == 52 then
				n22 = 0
				state = 11
			elseif state == 53 then
				if nil <= 2 then
					state = 56
				else
					state = 54
				end
			elseif state == 54 then
				if nil <= 3 then
					state = 65
				else
					state = 55
				end
			elseif state == 55 then
				if nil <= 4 then
					state = 68
				else
					state = 11
				end
			elseif state == 56 then
				if nil <= 0 then
					state = 70
				else
					state = 57
				end
			elseif state == 57 then
				if nil <= 1 then
					state = 58
				else
					state = 63
				end
			elseif state == 58 then
				n22 = str
				str = 0
				state = 10
			elseif state == 59 then
				state = 60
			elseif state == 60 then
				local v88 = fn9
				bit32.lshift(v83, 11)
				v88(n20, 1)

				if nil then
					state = 62
				else
					state = 61
				end
			elseif state == 61 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 62
			elseif state == 62 then
				n20 = fn6

				if v87 then
					state = 64
				else
					state = 63
				end
			elseif state == 63 then
				n21 = 0
				state = 65
			elseif state == 64 then
				n21 = v87
				state = 65
			elseif state == 65 then
				n20(n21 + 0, 2)
				fn9(string.sub(v79, 2, 2), v81)

				if nil then
					state = 67
				else
					state = 66
				end
			elseif state == 66 then
				fn6(132891451, 4)
				n = 160167421
				fn7()
				state = 67
			elseif state == 67 then
				local v88 = fn5
				local v89 = string.byte(v79, 2, 2)
				v88(48356262, v89)
				state = 68
			elseif state == 68 then
				return
			elseif state == 69 then
				str = n23
				state = 70
			elseif state == 70 then
				n20 = n20 * 10 + string.byte(v79, str, str) - 48
				state = 17
			end
		end
	end

	fn15("stdin:27: attempt to call a thread value", 345366052, "t")
	fn15("stdin:85: attempt to index boolean with string", 345366052, "t")
	fn15("input.lua:105: attempt to perform arithmetic (mul) on thread and nil", 345366052, "n")
	fn15("source.lua:136: attempt to get length of a boolean value", 345366052, "o")

	fn4 = function(arg)
		local fn16 = nil
		local v79 = string.match(arg, "%:(%d%d*)[^%p%P]?[%:\n\r]")
		local v80 = string.gmatch(arg, ":[^%s%S]-([0-9]+)[\n%:\r][^%c%C]?")()
		local v81, v82 = string.find(arg, "%:[^%c%C]?([0-9][0-9]*)[^%x%X]?[\n%:\r]")
		local flag = not v81
		local flag2

		if v81 then
			flag2 = not v82
		else
			flag2 = flag
		end

		if flag2 then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		local str = string.sub(arg, v81 + 1, v82 - 1)
		local v83 = nil
		local v84 = string.char(string.byte(arg, v81 + 1, v82 - 1))
		local v85 = str
		local v86 = nil
		local n20 = 0

		fn16 = function(arg2)
			fn9(info(1, "f"), fn16)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			local gsub = string.gsub

			if not fn9(info(2, "f"), gsub) then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			fn9(info(3, "f"), fn4)

			if not nil then
				fn6(132891451, 4)
				n = 160167421
				fn7()
			end

			v86 = arg2
			n20 += 1
		end

		local v87, v88 = string.gsub(arg, "[:][^%x%X]-([0-9][0-9]*)[^%w%W]*[\n%:\r][^%c%C]*", fn16, 1)
		fn9(n20, 1)

		if nil then
		else
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(v88, 1)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		local flag3 = not v79
		local flag4

		if v79 then
			flag4 = not v80
		else
			flag4 = flag3
		end

		if flag4 or not v85 or not v84 or not v86 then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		local n21 = v79 + 0
		local n22 = v80 + 0
		local n23 = v85 + 0
		local n24 = v84 + 0
		local n25 = v86 + 0
		fn9(v79, v80)
		local v89

		if nil then
			v89 = n22
		else
			v89 = n22
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(v80, v85)

		if not nil then
			local v90 = v83
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(v85, v84)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(v84, v86)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(n21, v89)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(v89, n23)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(n23, n24)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		fn9(n24, n25)

		if not nil then
			fn6(132891451, 4)
			n = 160167421
			fn7()
		end

		return n21
	end

	local v79 = fn4(result2)
	local v80 = fn4(result3)
	local v81 = fn4(result4)

	if fn9(v79, v80) then
		fn5(48356262, 184)
		n = v74
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(v80, v81) then
		fn5(48356262, 176)
	else
		fn6(132891451, 4)
		n = 160167421
		fn7()
	end

	if fn9(v81, v79) then
		fn5(48356262, 107)
	else
		local v82 = bit32.band(n17, v68)
		fn6(132891451, 4)
		n = 160167421
		fn7()
		n17 = v82 + 272
	end

	n = v74
	local v82 = table.pack(b_1())

	if v82[1] then
		local v83 = v82[3]
		local exitTo = nil
		local kind, v84, v85, v86

		while true do
			kind = type(v83)

			if fn9("function", kind) then
				v84, v85 = info(v83, "sl")

				if fn9("[C]", v84) then
					exitTo = 1
					break
				elseif fn9(v79, v85) then
					exitTo = 2
					break
				else
					v86 = bit32.bxor(v77, 134)
					fn6(132891451, 4)
					n = 160167421
					fn7()
					v77 = bit32.bxor(v86, 134)
					local v87 = table.pack(b_1())
					if v87[1] then
						v83 = v87[3]
						continue
					end
				end

				break
			else
				local v87 = table.pack(b_1())
				if v87[1] then
					v83 = v87[3]
					continue
				end
				break
			end
		end

		local exitTo3, exitTo2, exitTo5, exitTo4

		if exitTo == 1 then
			exitTo3 = nil

			while true do
				local v87 = table.pack(b_1())

				if v87[1] then
					v83 = v87[3]
					exitTo2 = nil

					while true do
						kind = type(v83)

						if fn9("function", kind) then
							v84, v85 = info(v83, "sl")

							if fn9("[C]", v84) then
								exitTo2 = 1
								break
							elseif fn9(v79, v85) then
								exitTo2 = 2
								break
							else
								v86 = bit32.bxor(v77, 134)
								fn6(132891451, 4)
								n = 160167421
								fn7()
								v77 = bit32.bxor(v86, 134)
								local v88 = table.pack(b_1())
								if v88[1] then
									v83 = v88[3]
									continue
								end
							end

							break
						else
							local v88 = table.pack(b_1())
							if v88[1] then
								v83 = v88[3]
								continue
							end
							break
						end
					end

					if exitTo2 ~= 1 then
						exitTo3 = 1
						break
					end
				else
					break
				end
			end

			if exitTo3 == 1 then
				if exitTo2 == 2 then
					exitTo5 = nil

					while true do
						local v87 = table.pack(b_1())

						if v87[1] then
							v83 = v87[3]
							exitTo4 = nil

							while true do
								kind = type(v83)

								if fn9("function", kind) then
									v84, v85 = info(v83, "sl")

									if fn9("[C]", v84) then
										exitTo4 = 1
										break
									elseif fn9(v79, v85) then
										exitTo4 = 2
										break
									else
										v86 = bit32.bxor(v77, 134)
										fn6(132891451, 4)
										n = 160167421
										fn7()
										v77 = bit32.bxor(v86, 134)
										local v88 = table.pack(b_1())
										if v88[1] then
											v83 = v88[3]
											continue
										end
									end

									break
								else
									local v88 = table.pack(b_1())
									if v88[1] then
										v83 = v88[3]
										continue
									end
									break
								end
							end

							if exitTo4 == 1 then
								exitTo5 = 1
								break
							elseif exitTo4 == 2 then
								continue
							end

							break
						else
							break
						end
					end

					if exitTo5 == 1 then
						while true do
							exitTo3 = nil

							while true do
								local v87 = table.pack(b_1())

								if v87[1] then
									v83 = v87[3]
									exitTo2 = nil

									while true do
										kind = type(v83)

										if fn9("function", kind) then
											v84, v85 = info(v83, "sl")

											if fn9("[C]", v84) then
												exitTo2 = 1
												break
											elseif fn9(v79, v85) then
												exitTo2 = 2
												break
											else
												v86 = bit32.bxor(v77, 134)
												fn6(132891451, 4)
												n = 160167421
												fn7()
												v77 = bit32.bxor(v86, 134)
												local v88 = table.pack(b_1())
												if v88[1] then
													v83 = v88[3]
													continue
												end
											end

											break
										else
											local v88 = table.pack(b_1())
											if v88[1] then
												v83 = v88[3]
												continue
											end
											break
										end
									end

									if exitTo2 ~= 1 then
										exitTo3 = 1
										break
									end
								else
									break
								end
							end

							if exitTo3 == 1 then
								if exitTo2 == 2 then
									exitTo5 = nil

									while true do
										local v87 = table.pack(b_1())

										if v87[1] then
											v83 = v87[3]
											exitTo4 = nil

											while true do
												kind = type(v83)

												if fn9("function", kind) then
													v84, v85 = info(v83, "sl")

													if fn9("[C]", v84) then
														exitTo4 = 1
														break
													elseif fn9(v79, v85) then
														exitTo4 = 2
														break
													else
														v86 = bit32.bxor(v77, 134)
														fn6(132891451, 4)
														n = 160167421
														fn7()
														v77 = bit32.bxor(v86, 134)
														local v88 = table.pack(b_1())
														if v88[1] then
															v83 = v88[3]
															continue
														end
													end

													break
												else
													local v88 = table.pack(b_1())
													if v88[1] then
														v83 = v88[3]
														continue
													end
													break
												end
											end

											if exitTo4 == 1 then
												exitTo5 = 1
												break
											elseif exitTo4 == 2 then
												continue
											end

											break
										else
											break
										end
									end

									if exitTo5 == 1 then
										continue
									end
								end
							end

							break
						end
					end
				end
			end
		elseif exitTo == 2 then
			exitTo5 = nil

			while true do
				local v87 = table.pack(b_1())

				if v87[1] then
					v83 = v87[3]
					exitTo4 = nil

					while true do
						kind = type(v83)

						if fn9("function", kind) then
							v84, v85 = info(v83, "sl")

							if fn9("[C]", v84) then
								exitTo4 = 1
								break
							elseif fn9(v79, v85) then
								exitTo4 = 2
								break
							else
								v86 = bit32.bxor(v77, 134)
								fn6(132891451, 4)
								n = 160167421
								fn7()
								v77 = bit32.bxor(v86, 134)
								local v88 = table.pack(b_1())
								if v88[1] then
									v83 = v88[3]
									continue
								end
							end

							break
						else
							local v88 = table.pack(b_1())
							if v88[1] then
								v83 = v88[3]
								continue
							end
							break
						end
					end

					if exitTo4 == 1 then
						exitTo5 = 1
						break
					elseif exitTo4 == 2 then
						continue
					end

					break
				else
					break
				end
			end

			if exitTo5 == 1 then
				while true do
					exitTo3 = nil
					local exitTo6 = nil

					while true do
						local v87 = table.pack(b_1())

						if v87[1] then
							v83 = v87[3]
							exitTo2 = nil

							while true do
								kind = type(v83)

								if fn9("function", kind) then
									v84, v85 = info(v83, "sl")

									if fn9("[C]", v84) then
										exitTo2 = 1
										break
									elseif fn9(v79, v85) then
										exitTo2 = 2
										break
									else
										v86 = bit32.bxor(v77, 134)
										fn6(132891451, 4)
										n = 160167421
										fn7()
										v77 = bit32.bxor(v86, 134)
										local v88 = table.pack(b_1())
										if v88[1] then
											v83 = v88[3]
											continue
										end
									end

									break
								else
									local v88 = table.pack(b_1())
									if v88[1] then
										v83 = v88[3]
										continue
									end
									break
								end
							end

							if exitTo2 ~= 1 then
								exitTo6 = 1
								break
							end
						else
							break
						end
					end

					if exitTo6 == 1 then
						exitTo3 = 1

						if exitTo3 == 1 then
							if exitTo2 == 2 then
								exitTo5 = nil

								while true do
									local v87 = table.pack(b_1())

									if v87[1] then
										v83 = v87[3]
										exitTo4 = nil

										while true do
											kind = type(v83)

											if fn9("function", kind) then
												v84, v85 = info(v83, "sl")

												if fn9("[C]", v84) then
													exitTo4 = 1
													break
												elseif fn9(v79, v85) then
													exitTo4 = 2
													break
												else
													v86 = bit32.bxor(v77, 134)
													fn6(132891451, 4)
													n = 160167421
													fn7()
													v77 = bit32.bxor(v86, 134)
													local v88 = table.pack(b_1())
													if v88[1] then
														v83 = v88[3]
														continue
													end
												end

												break
											else
												local v88 = table.pack(b_1())
												if v88[1] then
													v83 = v88[3]
													continue
												end
												break
											end
										end

										if exitTo4 == 1 then
											exitTo5 = 1
											break
										elseif exitTo4 == 2 then
											continue
										end

										break
									else
										break
									end
								end

								if exitTo5 == 1 then
									continue
								end
							end
						end
					elseif exitTo3 == 1 then
						if exitTo2 == 2 then
							exitTo5 = nil

							while true do
								local v87 = table.pack(b_1())

								if v87[1] then
									v83 = v87[3]
									exitTo4 = nil

									while true do
										kind = type(v83)

										if fn9("function", kind) then
											v84, v85 = info(v83, "sl")

											if fn9("[C]", v84) then
												exitTo4 = 1
												break
											elseif fn9(v79, v85) then
												exitTo4 = 2
												break
											else
												v86 = bit32.bxor(v77, 134)
												fn6(132891451, 4)
												n = 160167421
												fn7()
												v77 = bit32.bxor(v86, 134)
												local v88 = table.pack(b_1())
												if v88[1] then
													v83 = v88[3]
													continue
												end
											end

											break
										else
											local v88 = table.pack(b_1())
											if v88[1] then
												v83 = v88[3]
												continue
											end
											break
										end
									end

									if exitTo4 == 1 then
										exitTo5 = 1
										break
									elseif exitTo4 == 2 then
										continue
									end

									break
								else
									break
								end
							end

							if exitTo5 == 1 then
								continue
							end
						end
					end

					break
				end
			end
		end
	end

	fn10(nil --[[ the caller's registers ]], 477950703)
	setmetatable(nil --[[ the caller's registers ]], nil)
	local tbl9 = {}
	local tbl10 = {}
	local n20 = 241
	local n21 = 227
	local tbl11 = { -1, v78, 255, 1, nil }

	while true do
		local v83 = tbl11[4]
		local v84 = tbl11[3]
		local n22 = tbl11[1] + v83
		local flag = v83 <= 0
		tbl11[1] = n22

		if n22 <= v84 then
			local v85 = n22
			local n23 = (n20 * v85 + n21) % 256
			local n24 = (n20 * n23 + n21) % 256
			local n25 = (n20 * n24 + n21) % 256
			local n26 = (n20 * n25 + n21) % 256
			tbl9[v85] = n23 + n24 * 256 + n25 * 65536 + n26 * 16777216
			tbl10[v85] = n26
		else
			break
		end
	end
end

buffer.create(16)
luraph_runtime5(nil, nil, table.pack(r98, r99))

do
	local n18 = n17 + 504503137

	local function fn15(arg, arg2, arg3)
		local state = 1
		local v78, v79, v80, tbl5, v81, n19, n20, readu8, v82, n21, n22, v83, n23, flag, flag2, flag3, flag4, v84, n24, v85, v86

		while true do
			if state == 1 then
				v78 = arg
				v79 = arg2
				v80 = arg3
				tbl5 = {}
				v81 = buffer.readu8(v78, v79)

				if nil then
					state = 6
				else
					state = 2
				end
			elseif state == 2 then
				local v87 = buffer.readu8(v78, v79 + 1)

				if nil then
					state = 5
				else
					state = 3
				end
			elseif state == 3 then
				state = 4
			elseif state == 4 then
				upv119 = 48356262
				;(nil)()
				state = 4
			elseif state == 5 then
				local n25 = bit32.band(nil, n18) - 4259046640
				error("devirt: symbolic value store into proto array (at 26:1001)")
			elseif state == 6 then
				n19 = v79 + 1
				n20 = v81 - 58893
				readu8 = buffer.readu8
				local v87 = readu8(v78, n19)

				if nil then
					state = 12
				else
					state = 7
				end
			elseif state == 7 then
				v82 = buffer.readu8(v78, n19 + 1)

				if nil then
					state = 11
				else
					state = 8
				end
			elseif state == 8 then
				local v87 = buffer.readu8(v78, n19 + 2)

				if nil then
					state = 10
				else
					state = 9
				end
			elseif state == 9 then
				local v87 = buffer.readu8(v78, n19 + 3)
				n19 += 4
				state = 13
			elseif state == 10 then
				local v87 = table.pack(bit32.band(nil, 4294967295))
				local v88 = table.pack(bit32.band(nil, 4294967295))
				local v89 = table.pack(bit32.band(v87[1], 65535))
				local v90 = table.pack(bit32.rshift(v87[1], 16))
				local v91 = table.pack(bit32.band(v88[1], 65535))
				bit32.band(v89[1] * v91[1] + bit32.lshift(bit32.band(v89[1] * bit32.rshift(v88[1], 16) + v90[1] * v91[1], 65535), 16), 4294967295)
				local v92 = table.pack(bit32.band(nil, 4294967295))
				local v93 = table.pack(bit32.band(v80, 4294967295))
				local v94 = table.pack(bit32.band(v92[1], 65535))
				local v95 = table.pack(bit32.rshift(v92[1], 16))
				local v96 = table.pack(bit32.band(v93[1], 65535))
				bit32.band(v94[1] * v96[1] + bit32.lshift(bit32.band(v94[1] * bit32.rshift(v93[1], 16) + v95[1] * v96[1], 65535), 16), 4294967295)
				error("devirt: symbolic value store into proto array (at 26:572)")
			elseif state == 11 then
				n19 += 2
				state = 13
			elseif state == 12 then
				n21 = nil % 2711724449

				if bit32.bxor(readu8, 333982661) ~= 386301156 then
					state = 13
				else
					state = 24
				end
			elseif state == 13 then
				local v87 = buffer.readu8(v78, n19)
				n19 += 1
				n22 = v80 + nil
				tbl5[4] = v87 ~= 0
				v83 = table.create(n20)
				tbl5[6] = v83

				if n18 ~= 249171880 then
					state = 14
				else
					state = 27
				end
			elseif state == 14 then
				n21 = { n21, n20 + 0, nil, 1, 0 }
				n20 = v83
				state = 15
			elseif state == 15 then
				local v87 = n21[4]
				local v88 = n21[2]
				n23 = n21[5] + v87
				flag = v87 <= 0
				flag2 = not flag
				flag3 = n23 >= v88
				flag4 = n23 <= v88

				if flag then
					state = 17
				else
					state = 16
				end
			elseif state == 16 then
				flag3 = flag

				if flag2 then
					state = 19
				else
					state = 18
				end
			elseif state == 17 then
				if flag2 then
					state = 19
				else
					state = 18
				end
			elseif state == 18 then
				flag4 = flag2

				if flag3 then
					state = 21
				else
					state = 20
				end
			elseif state == 19 then
				if flag3 then
					state = 21
				else
					state = 20
				end
			elseif state == 20 then
				flag3 = flag4
				state = 21
			elseif state == 21 then
				n21[5] = n23

				if flag3 then
					state = 26
				else
					state = 22
				end
			elseif state == 22 then
				v84 = buffer.readu8(v78, n19)
				local n25 = n22 + n18

				if nil then
					state = 25
				else
					state = 23
				end
			elseif state == 23 then
				state = 24
			elseif state == 24 then
				buffer.readu8(v78, n19 + 1)
				error("devirt: symbolic value store into proto array (at 26:803)")
			elseif state == 25 then
				buffer.create(v84)
				bit32.band(nil, nil)
				bit32.bxor(4294967295, nil)
				return 477950703
			elseif state == 26 then
				v82 = n23
				state = 27
			elseif state == 27 then
				n24 = buffer.readu8(v78, n19)

				if nil then
					state = 33
				else
					state = 28
				end
			elseif state == 28 then
				v85 = buffer.readu8(v78, n19 + 1)

				if nil then
					state = 32
				else
					state = 29
				end
			elseif state == 29 then
				v86 = buffer.readu8(v78, n19 + 2)

				if nil then
					state = 31
				else
					state = 30
				end
			elseif state == 30 then
				local v87 = buffer.readu8(v78, n19 + 3)
				n24 = (n24 - 128) * 16384 + v85 - 128 + (v86 - 128) * 2097152 + v87 % 128 * 128 + (v87 - v87 % 128) * 2097152
				n19 += 4
				state = 34
			elseif state == 31 then
				n24 = (n24 - 128) * 16384 + (v85 - 128) * 128 + v86
				n19 += 3
				state = 34
			elseif state == 32 then
				n24 = (n24 - 128) * 128 + v85
				n19 += 2
				state = 34
			elseif state == 33 then
				n19 += 1
				state = 34
			elseif state == 34 then
				n20[v82] = n24
				state = 15
			end
		end
	end
end

fn6 = #v55
error("devirt: corrupt/encrypted register index 9739 (at 26:9462)")
