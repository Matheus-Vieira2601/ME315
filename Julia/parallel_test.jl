using Base.Threads
using Printf

# --- 1. A Tarefa "Pesada" ---
# Esta é a função que queremos executar milhões de vezes.
# É intencionalmente lenta para que possamos ver a diferença.
function heavy_calc(x::Float64)::Float64
    val = x
    # Um loop sem sentido apenas para gastar tempo de CPU
    for _ in 1:500
        val = sin(val) + cos(val)
    end
    return val
end

# --- 2. Versão Serial ---
# Um loop 'for' padrão. Uma thread faz todo o trabalho,
# uma iteração após a outra.
function run_serial(data::Vector{Float64})::Vector{Float64}
    n = length(data)
    results = similar(data) # Aloca array para os resultados
    
    for i in 1:n
        results[i] = heavy_calc(data[i])
    end
    return results
end

# --- 3. Versão Paralela ---
# Usando Threads.@threads. O Julia divide o loop "for"
# e distribui as iterações (i) pelas threads disponíveis.
function run_parallel(data::Vector{Float64})::Vector{Float64}
    n = length(data)
    results = similar(data) # Aloca array para os resultados
    
    # O "mestre de cerimônias" da paralelização
    @threads for i in 1:n
        # Cada thread escreve em uma parte *diferente* de 'results',
        # por isso é seguro e não há conflito.
        results[i] = heavy_calc(data[i])
    end
    return results
end

# --- 4. Execução e Comparação ---
function main()
    # Ponto de partida: Verifique quantas threads o Julia pode usar.
    num_threads = Threads.nthreads()
    @printf("Executando com %d thread(s).\n", num_threads)
    
    if num_threads == 1
        println("\nAVISO: O Julia está rodando com apenas 1 thread.")
        println("A versão 'paralela' não será mais rápida e pode até ser mais lenta.")
        println("Reinicie o Julia com '-t auto' (ex: julia -t auto seu_script.jl) para ver o ganho.")
    end

    # Criando um array grande com dados aleatórios
    N = 10_000_000 # 10 milhões de elementos
    println("\nPreparando $N elementos...")
    data = rand(N)

    println("Iniciando teste SERIAL...")
    # Usamos @time para medir o tempo e a alocação de memória
    # @time aquece o código (compilação JIT) na primeira execução.
    # Vamos executar uma vez para "aquecer" e depois cronometrar.
    
    run_serial(data[1:10]) # Aquecimento
    time_serial = @elapsed run_serial(data)
    @printf("Tempo Serial:   %.4f segundos\n", time_serial)
    
    println("\nIniciando teste PARALELO...")
    run_parallel(data[1:10]) # Aquecimento
    time_parallel = @elapsed run_parallel(data)
    @printf("Tempo Paralelo: %.4f segundos\n", time_parallel)

    # --- 5. A Análise ---
    println("\n--- Análise ---")
    if num_threads > 1 && time_parallel < time_serial
        speedup = time_serial / time_parallel
        @printf("A versão paralela foi %.2fx mais rápida!\n", speedup)
    elseif num_threads > 1
        println("A versão paralela não foi mais rápida. Isso pode ocorrer se a tarefa for muito pequena,")
        println("e o custo de 'organizar' as threads for maior que o ganho.")
    else
        println("Execute com múltiplas threads para ver a diferença.")
    end
end

# Vamos rodar!
main()