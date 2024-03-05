import Base: ==, isequal

const thing1_name = "AWSCRT_Test1"

abstract type Comparable end

==(a::T, b::T) where {T<:Comparable} = isequal(a, b)

function isequal(a::T, b::T) where {T<:Comparable}
    f = fieldnames(T)
    isequal(getfield.(Ref(a), f), getfield.(Ref(b), f))
end

function wait_for(predicate, timeout = Timer(5))
    while !predicate() && isopen(timeout)
        sleep(0.1)
    end

    if !isopen(timeout)
        error("wait_for timeout")
    end
end

sort_pairs(it) = sort(it; by = x -> x[begin])

function new_tls_ctx()
    tls_ctx_options = if haskey(ENV, "CERT_STRING")
        create_client_with_mtls(
            ENV["CERT_STRING"],
            ENV["PRI_KEY_STRING"],
            ca_filepath = joinpath(@__DIR__, "certs", "AmazonRootCA1.pem"),
        )
    elseif haskey(ENV, "CERT_PATH")
        create_client_with_mtls_from_path(
            ENV["CERT_PATH"],
            ENV["PRI_KEY_PATH"],
            ca_filepath = joinpath(@__DIR__, "certs", "AmazonRootCA1.pem"),
        )
    else
        error("could not find cert in ENV")
    end
    return ClientTLSContext(tls_ctx_options)
end

function new_mqtt_connection()
    client = MQTTClient(new_tls_ctx())
    connection = MQTTConnection(client)
    client_id = random_client_id()
    @show client_id
    task = connect(connection, ENV["ENDPOINT"], 8883, client_id)
    @test fetch(task) == Dict(:session_present => false)
    return connection
end

"""
Generates a test-independently-random client ID. Reusing the same client ID in multiple tests creates many problems.
"""
random_client_id() = randstring(MersenneTwister(), 48)

random_shadow_name() = "shadow-$(randstring(MersenneTwister(), 6))"
