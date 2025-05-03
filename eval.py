import os
import subprocess
import time
import json
import pprint
import re
import psutil

tmp_dir = "./tmp_files"
log_file = "./eval.log"
timeout = 10 * 60 #10 min
timeout_ddknife = 10*60 #10 min

def log(content):
    with open(log_file, "a") as file:
        file.write(content + "\n")
        file.flush()


def run_encoding(uvl_file, dimacs_file, kind):
    try:
        #command = "java -Xmx512m -jar ./lib/fm-metamodel-1.1-jar-with-dependencies.jar \"" + uvl_file + "\" \"" + dimacs_file + "\" " + kind
        command = "timeout " + str(timeout) + " java -Xss1g -jar ./lib/ma-eval-1.0-SNAPSHOT-jar-with-dependencies.jar \"" + uvl_file + "\" \"" + dimacs_file + "\" " + kind
        start_time = time.perf_counter()
        process = subprocess.Popen(command, shell=True)
        process.communicate()
        process.wait()
        end_time = time.perf_counter()
        if process.returncode == 124:
            raise subprocess.TimeoutExpired(cmd=command, timeout=timeout)
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, command)
        return end_time - start_time
    except subprocess.TimeoutExpired as e:
        log("timeout")
        process.kill()
        process.wait()
        raise e

def run_d4(dimacs_file, result_file_path):
    command = "timeout " + str(timeout) + " ./lib/d4 \"" + dimacs_file + "\" -dDNNF -out=" + dimacs_file + "_d4.nnf" + " > " + result_file_path
    start_time = time.perf_counter()
    process = subprocess.Popen(command, shell=True)
    process.communicate()
    process.wait()
    end_time = time.perf_counter()
    if process.returncode == 124:
        raise subprocess.TimeoutExpired(cmd=command, timeout=timeout)
    if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, command)
    return end_time - start_time

def run_p2d(opb_file, result_file_path):
    command = "timeout " + str(timeout) + " ./lib/p2d \"" + opb_file + "\"" + " -m ddnnf -o " + "\"" + opb_file + "_p2d.nnf" + "\"" + " > " + result_file_path
    start_time = time.perf_counter()
    process = subprocess.Popen(command, shell=True)
    process.communicate()
    process.wait()
    end_time = time.perf_counter()
    if process.returncode == 124:
        raise subprocess.TimeoutExpired(cmd=command, timeout=timeout)
    if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, command)
    return end_time - start_time

def measure_dimacs_encoding(model_dir, result, run_n_times, stop_after_n_timeouts):
    files = []
    timeout_counter = 0
    if stop_after_n_timeouts > 0:
        files = get_sorted_files(model_dir)
    else:
        files = get_unsorted_files(model_dir)
    for file in files:
        abs_path = os.path.abspath(file)
        target_path = os.path.join(".", "tmp_files", os.path.basename(file) + str(hash(abs_path)) + ".dimacs")
        result.setdefault(abs_path, {})
        result[abs_path].setdefault("dimacs_time", [])
        model_timeout_counter = 0
        for i in range(0, run_n_times):
            log("starting dimacs encoding (" + str(i) + "): " + abs_path)
            try:
                result[abs_path]["dimacs_time"].append(run_encoding(abs_path, target_path, "dimacs"))
                result[abs_path]["dimacs_file_path"] = target_path
                result[abs_path]["dimacs_number_variables"] = extract_number_variables_from_dimacs_file(target_path)
            except subprocess.TimeoutExpired as e:
                result[abs_path]["dimacs_time"].append("TIMEOUT")
                model_timeout_counter += 1
            except subprocess.CalledProcessError as e:
                result[abs_path]["dimacs_time"].append("ERROR: " + str(e))
                model_timeout_counter += 1
            log("finished dimacs encoding: " + abs_path)
            time.sleep(1.0)
        if model_timeout_counter == run_n_times:
            timeout_counter += 1
        else:
            timeout_counter = 0
        if stop_after_n_timeouts > 0 and timeout_counter >= stop_after_n_timeouts:
            break

def extract_number_variables_from_dimacs_file(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            if line.startswith("p cnf"):
                # Split the line into parts and extract the third value
                parts = line.split()
                if len(parts) >= 3:
                    return int(parts[2])
    raise ValueError("No valid 'p cnf' line found in the file.")

def measure_opb_encoding(model_dir, result, run_n_times, stop_after_n_timeouts):
    files = []
    timeout_counter = 0
    if stop_after_n_timeouts > 0:
        files = get_sorted_files(model_dir)
    else:
        files = get_unsorted_files(model_dir)

    for file in files:
        abs_path = os.path.abspath(file)
        target_path = os.path.join(".", "tmp_files", os.path.basename(file) + str(hash(abs_path)) + ".opb")
        result.setdefault(abs_path, {})
        result[abs_path].setdefault("opb_time", [])
        model_timeout_counter = 0
        for i in range(0, run_n_times):
            try:
                log("starting opb encoding: (" + str(i) + "): " + abs_path)
                result[abs_path]["opb_time"].append(run_encoding(abs_path, target_path, "opb"))
                result[abs_path]["opb_file_path"] = target_path
                result[abs_path]["opb_number_variables"] = extract_number_variables_from_opb_file(target_path)
            except subprocess.TimeoutExpired as e:
                result[abs_path]["opb_time"].append("TIMEOUT")
                model_timeout_counter += 1
            except subprocess.CalledProcessError as e:
                result[abs_path]["opb_time"].append("ERROR: " + str(e))
                model_timeout_counter += 1
            log("finished opb encoding: " + abs_path)
            time.sleep(1.0)
        if model_timeout_counter == run_n_times:
            timeout_counter += 1
        else:
            timeout_counter = 0
        if stop_after_n_timeouts > 0 and timeout_counter >= stop_after_n_timeouts:
            break
            

def measure_d4(result, run_n_times, stop_after_n_timeouts):
    timeout_counter = 0
    for model in result:
        if "dimacs_file_path" in result[model]:
            result[model].setdefault("d4_time", [])
            result_path = os.path.join(tmp_dir, os.path.basename(result[model]["dimacs_file_path"])) + "_result.txt"
            model_timeout_counter = 0
            for i in range(0, run_n_times):
                try:
                    log("starting d4: (" + str(i) + "): " + model)
                    result[model]["d4_time"].append(run_d4(result[model]["dimacs_file_path"], result_path))
                    result[model]["d4_output_path"] = result_path
                    result[model]["d4_ddnnf_path"] = result[model]["dimacs_file_path"] + "_d4.nnf"
                except subprocess.TimeoutExpired as e:
                    result[model]["d4_time"].append("TIMEOUT")
                    model_timeout_counter += 1
                except subprocess.CalledProcessError as e:
                    result[model]["d4_time"].append("ERROR: " + str(e))
                    model_timeout_counter += 1
                log("end d4: " + model)
                time.sleep(1.0)
            if model_timeout_counter == run_n_times:
                timeout_counter += 1
            else:
                timeout_counter = 0
            if stop_after_n_timeouts > 0 and timeout_counter >= stop_after_n_timeouts:
                break

def measure_p2d(result, run_n_times, stop_after_n_timeouts):
    timeout_counter = 0
    for model in result:
        if "opb_file_path" in result[model]:
            result[model].setdefault("p2d_time", [])
            result_path = os.path.join(tmp_dir, os.path.basename(result[model]["opb_file_path"])) + "_result.txt"
            model_timeout_counter = 0
            for i in range(0, run_n_times):
                try:
                    log("starting p2d: (" + str(i) + "): " + model)
                    result[model]["p2d_time"].append(run_p2d(result[model]["opb_file_path"], result_path))
                    result[model]["p2d_output_path"] = result_path
                    result[model]["p2d_ddnnf_path"] = result[model]["opb_file_path"] + "_p2d.nnf"
                except subprocess.TimeoutExpired as e:
                    result[model]["p2d_time"].append("TIMEOUT")
                    model_timeout_counter += 1
                except subprocess.CalledProcessError as e:
                    result[model]["p2d_time"].append("ERROR: " + str(e))
                    model_timeout_counter += 1
                log("end p2d: " + model)
                time.sleep(1.0)
            if model_timeout_counter == run_n_times:
                timeout_counter += 1
            else:
                timeout_counter = 0
            if stop_after_n_timeouts > 0 and timeout_counter >= stop_after_n_timeouts:
                break

def extract_number_variables_from_opb_file(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            if line.startswith("#variable="):
                # Split the line into parts and extract the third value
                parts = line.split()
                if len(parts) >= 4:
                    return int(parts[1])
    raise ValueError("No valid '#variable=' line found in the file.")

def count_literals_dimacs(dimacs_file):
    try:
        counter = 0
        with open(dimacs_file, 'r') as file:
            for line in file:
                line = line.strip()

                if line.startswith('c') or line.startswith('p'):
                    continue

                for literal in line.split():
                    if literal == '0':
                        continue
                    counter += 1

        return counter
    except FileNotFoundError:
        log(f"Error: File '{dimacs_file}' not found.")
        return -1

def count_literals_opb(opb_file):
    try:
        counter = 0
        with open(opb_file, 'r') as file:
            for line in file:
                line = line.strip()

                if line.startswith('#'):
                    continue

                literals = re.findall(r'"(.*?)"', line)
                counter += len(literals)

        return counter
    except FileNotFoundError:
        log(f"Error: File '{opb_file}' not found.")
        return -1

def measure_dimacs_size(result):
    for model in result:
        if "dimacs_file_path" in result[model]:
            result[model]["dimacs_size"] = count_literals_dimacs(result[model]["dimacs_file_path"])


def measure_opb_size(result):
    for model in result:
        if "opb_file_path" in result[model]:
            result[model]["opb_size"] = count_literals_opb(result[model]["opb_file_path"])

def measure_p2d_ddnnf_size(result):
    for model in result:
        if "p2d_ddnnf_path" in result[model]:
            try:
                log("start ddnife on: " + result[model]["p2d_ddnnf_path"])
                result[model]["p2d_ddnnf_size"] = count_ddnnf_literals(result[model]["p2d_ddnnf_path"])
            except subprocess.CalledProcessError as e:
                result[model]["p2d_ddnnf_size"] = "ERROR: " + str(e)
            log("finished ddnife on: " + result[model]["p2d_ddnnf_path"])

def measure_d4_ddnnf_size(result):
    for model in result:
        if "d4_ddnnf_path" in result[model]:
            try:
                log("start ddnife on: " + result[model]["d4_ddnnf_path"])
                result[model]["d4_ddnnf_size"] = count_ddnnf_literals(result[model]["d4_ddnnf_path"])
            except subprocess.CalledProcessError as e:
                result[model]["d4_ddnnf_size"] = "ERROR: " + str(e)
            log("finished ddnife on: " + result[model]["d4_ddnnf_path"])
            
def count_ddnnf_literals(ddnnf_path):
    command = "timeout " + str(timeout_ddknife) + " ./lib/ddnnife -i " + ddnnf_path + " --heuristics"
    process = subprocess.Popen(command, shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)

    overall_node_count = None

    # Read stderr line by line
    for line in process.stderr:
        match = re.search(r"The overall node count is (\d+)\.", line)
        if match:
            overall_node_count = int(match.group(1))
            kill_process_tree(process.pid)
            break

    process.wait()  # Ensure process cleanup

    if overall_node_count is not None:
        return overall_node_count
    else:
        return "Overall node count not found."
    
def kill_process_tree(pid):
    """ Kill a process and all its children. """
    try:
        parent = psutil.Process(pid)  # Get parent process
        for child in parent.children(recursive=True):  # Get all children
            child.kill()  # Kill each child
        parent.kill()  # Finally kill the parent
    except psutil.NoSuchProcess:
        pass  # Process already gone

def get_d4_mcs(result):
    for model in result:
        if "d4_output_path" in result[model]:
            try:
                log("start d4 ddknife mc: " + result[model]["d4_ddnnf_path"])
                result[model]["d4_mc"] = mc_from_ddnnf(result[model]["d4_ddnnf_path"], result[model]["dimacs_number_variables"]) #d4_mc_from_output(result[model]["d4_output_path"])
            except subprocess.CalledProcessError as e:
                result[model]["d4_mc"] = "ERROR: " + str(e)
            log("end d4 ddknife mc: " + result[model]["d4_ddnnf_path"])

def get_p2d_mcs(result):
    for model in result:
        if "p2d_output_path" in result[model]:
            try:
                log("start p2d ddknife mc: " + result[model]["p2d_ddnnf_path"])
                result[model]["p2d_mc"] = mc_from_ddnnf(result[model]["p2d_ddnnf_path"], result[model]["opb_number_variables"]) #p2d_mc_from_output(result[model]["p2d_output_path"])
            except subprocess.CalledProcessError as e:
                result[model]["p2d_mc"] = "ERROR: " + str(e)
            log("end p2d ddknife mc: " + result[model]["p2d_ddnnf_path"])

def d4_mc_from_output(output_file):
    with open(output_file, 'r') as file:
        for line in file:
            line = line.strip()

            if line.startswith("s"):
                return line.split()[1]
    return "ERROR"

def mc_from_ddnnf(ddnnf_path, number_variables):
    command = "timeout " + str(timeout_ddknife) + " ./lib/ddnnife -i " + ddnnf_path + " -t " + str(number_variables) + " count"
    process = subprocess.Popen(command, shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    stdout, stderr = process.communicate()
    process.wait()
    if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, command)
    return stdout

def p2d_mc_from_output(output_file):
    with open(output_file, 'r') as file:
        for line in file:
            line = line.strip()

            if line.startswith("result"):
                return line.split()[1]
    return "ERROR"

def save_dict_to_file(dictionary, file_path):
    try:
        with open(file_path, 'w') as file:
            json.dump(dictionary, file, indent=4)
    except Exception as e:
        log(f"An error occurred while saving the dictionary: {e}")

def get_sorted_files(model_dir):
    files_with_index = []

    # Walk through all directories and files
    for root, _, files in os.walk(model_dir):
        for file in files:
            match = re.match(r"root_(\d+)\.uvl$", file)  # Extract number i
            if match:
                index = int(match.group(1))  # Convert i to an integer
                files_with_index.append((index, os.path.join(root, file)))

    # Sort by extracted integer
    files_with_index.sort()

    # Return only the sorted file paths
    return [file_path for _, file_path in files_with_index]

def get_unsorted_files(model_dir):
    all_files = []
    for root, _, files in os.walk(model_dir):
        for file in files:
            all_files.append(os.path.join(root, file))
    return all_files

def eval_modelset(name: str, model_dir, number_runs, stop_after_n_timeouts):
    result_path = f"./results/{name}_result.json"
    result = {}
    os.makedirs(tmp_dir, exist_ok=True)
    start_time = time.perf_counter()
    measure_dimacs_encoding(model_dir, result, number_runs, stop_after_n_timeouts)
    measure_opb_encoding(model_dir, result, number_runs, stop_after_n_timeouts)
    measure_d4(result, number_runs, stop_after_n_timeouts)
    get_d4_mcs(result)
    measure_p2d(result, number_runs, stop_after_n_timeouts)
    get_p2d_mcs(result)
    measure_dimacs_size(result)
    measure_opb_size(result)
    measure_d4_ddnnf_size(result)
    measure_p2d_ddnnf_size(result)
    end_time = time.perf_counter()
    duration = end_time - start_time
    log("time to evaluate: " + str(duration))
    pprint.pprint(result) 
    save_dict_to_file(result, result_path)

def main():
    number_runs = 3
    stop_after_n_timeouts = 3
    eval_modelset("test", "/home/stefan/test", 1, -1)
    #repo_model_eval(number_runs)
    #rnd_model_eval(number_runs)
    #iso_model_eval(number_runs, stop_after_n_timeouts)
    #eval_modelset("tmp", "/home/stefan/test", number_runs, -1)
    #eval_modelset("tmp", "/home/stefan/test/rnd-models")
    #real_world_eval(number_runs)

def rnd_model_eval(number_runs):
    eval_modelset("rnd_just_one_groupCard_small", "./rnd_models/just_one/groupCard/small", number_runs, -1)
    eval_modelset("rnd_just_one_groupCard_medium", "./rnd_models/just_one/groupCard/medium", number_runs, -1)
    eval_modelset("rnd_just_one_groupCard_large", "./rnd_models/just_one/groupCard/large", number_runs, -1)
    eval_modelset("rnd_just_one_featureCard_small", "./rnd_models/just_one/featureCard/small", number_runs, -1)
    eval_modelset("rnd_just_one_featureCard_medium", "./rnd_models/just_one/featureCard/medium", number_runs, -1)
    eval_modelset("rnd_just_one_featureCard_large", "./rnd_models/just_one/featureCard/large", number_runs, -1)
    eval_modelset("rnd_just_one_expression_small", "./rnd_models/just_one/expression/small", number_runs, -1)
    eval_modelset("rnd_just_one_expression_medium", "./rnd_models/just_one/expression/medium", number_runs, -1)
    eval_modelset("rnd_just_one_expression_large", "./rnd_models/just_one/expression/large", number_runs, -1)
    eval_modelset("rnd_just_one_aggregate_small", "./rnd_models/just_one/aggregate/small", number_runs, -1)
    eval_modelset("rnd_just_one_aggregate_medium", "./rnd_models/just_one/aggregate/medium", number_runs, -1)
    eval_modelset("rnd_just_one_aggregate_large", "./rnd_models/just_one/aggregate/large", number_runs, -1)
    eval_modelset("rnd_except_one_groupCard_small", "./rnd_models/except_one/groupCard/small", number_runs, -1)
    eval_modelset("rnd_except_one_groupCard_medium", "./rnd_models/except_one/groupCard/medium", number_runs, -1)
    eval_modelset("rnd_except_one_groupCard_large", "./rnd_models/except_one/groupCard/large", number_runs, -1)
    eval_modelset("rnd_except_one_featureCard_small", "./rnd_models/except_one/featureCard/small", number_runs, -1)
    eval_modelset("rnd_except_one_featureCard_medium", "./rnd_models/except_one/featureCard/medium", number_runs, -1)
    eval_modelset("rnd_except_one_featureCard_large", "./rnd_models/except_one/featureCard/large", number_runs, -1)
    eval_modelset("rnd_except_one_expression_small", "./rnd_models/except_one/expression/small", number_runs, -1)
    eval_modelset("rnd_except_one_expression_medium", "./rnd_models/except_one/expression/medium", number_runs, -1)
    eval_modelset("rnd_except_one_expression_large", "./rnd_models/except_one/expression/large", number_runs, -1)
    eval_modelset("rnd_except_one_aggregate_small", "./rnd_models/except_one/aggregate/small", number_runs, -1)
    eval_modelset("rnd_except_one_aggregate_medium", "./rnd_models/except_one/aggregate/medium", number_runs, -1)
    eval_modelset("rnd_except_one_aggregate_large", "./rnd_models/except_one/aggregate/large", number_runs, -1)
    eval_modelset("rnd_all_small", "./rnd_models/all/small", number_runs, -1)
    eval_modelset("rnd_all_medium", "./rnd_models/all/medium", number_runs, -1)
    eval_modelset("rnd_all_large", "./rnd_models/all/large", number_runs, -1)

def repo_model_eval(number_runs):
    eval_modelset("repo", "./models", number_runs, -1)

def iso_model_eval(number_runs, stop_after_n_timeouts):
    alt_model_eval(number_runs, stop_after_n_timeouts)
    group_card_model_eval(number_runs, stop_after_n_timeouts)
    feature_card_model_eval(number_runs, stop_after_n_timeouts)
    div_model_eval(number_runs, stop_after_n_timeouts)
    prod_model_eval(number_runs, stop_after_n_timeouts)
    sum_model_eval(number_runs, stop_after_n_timeouts)

def sum_model_eval(number_runs, stop_after_n_timeouts):
    eval_modelset("sum1", "./iso_models/sum/sum_1", number_runs, stop_after_n_timeouts)
    eval_modelset("sum2", "./iso_models/sum/sum_2", number_runs, stop_after_n_timeouts)
    eval_modelset("sum3", "./iso_models/sum/sum_3", number_runs, stop_after_n_timeouts)
    eval_modelset("sum4", "./iso_models/sum/sum_4", number_runs, stop_after_n_timeouts)
    eval_modelset("sum5", "./iso_models/sum/sum_5", number_runs, stop_after_n_timeouts)
    eval_modelset("sum6", "./iso_models/sum/sum_6", number_runs, stop_after_n_timeouts)
    eval_modelset("sum7", "./iso_models/sum/sum_7", number_runs, stop_after_n_timeouts)
    eval_modelset("sum8", "./iso_models/sum/sum_8", number_runs, stop_after_n_timeouts)
    eval_modelset("sum9", "./iso_models/sum/sum_9", number_runs, stop_after_n_timeouts)

def prod_model_eval(number_runs, stop_after_n_timeouts):
    eval_modelset("prod1", "./iso_models/product/product_1", number_runs, stop_after_n_timeouts)
    eval_modelset("prod2", "./iso_models/product/product_2", number_runs, stop_after_n_timeouts)
    eval_modelset("prod3", "./iso_models/product/product_3", number_runs, stop_after_n_timeouts)
    eval_modelset("prod4", "./iso_models/product/product_4", number_runs, stop_after_n_timeouts)
    eval_modelset("prod5", "./iso_models/product/product_5", number_runs, stop_after_n_timeouts)
    eval_modelset("prod6", "./iso_models/product/product_6", number_runs, stop_after_n_timeouts)
    eval_modelset("prod7", "./iso_models/product/product_7", number_runs, stop_after_n_timeouts)
    eval_modelset("prod8", "./iso_models/product/product_8", number_runs, stop_after_n_timeouts)
    eval_modelset("prod9", "./iso_models/product/product_9", number_runs, stop_after_n_timeouts)

def div_model_eval(number_runs, stop_after_n_timeouts):
    eval_modelset("div1", "./iso_models/div/div_1", number_runs, stop_after_n_timeouts)
    eval_modelset("div2", "./iso_models/div/div_2", number_runs, stop_after_n_timeouts)
    eval_modelset("div3", "./iso_models/div/div_3", number_runs, stop_after_n_timeouts)
    eval_modelset("div4", "./iso_models/div/div_4", number_runs, stop_after_n_timeouts)
    eval_modelset("div5", "./iso_models/div/div_5", number_runs, stop_after_n_timeouts)
    eval_modelset("div6", "./iso_models/div/div_6", number_runs, stop_after_n_timeouts)
    eval_modelset("div7", "./iso_models/div/div_7", number_runs, stop_after_n_timeouts)
    eval_modelset("div8", "./iso_models/div/div_8", number_runs, stop_after_n_timeouts)
    eval_modelset("div9", "./iso_models/div/div_9", number_runs, stop_after_n_timeouts)

def alt_model_eval(number_runs, stop_after_n_timeouts):
    eval_modelset("alternative", "./iso_models/alternative", number_runs, stop_after_n_timeouts)

def group_card_model_eval(number_runs, stop_after_n_timeouts):
    eval_modelset("groupCard_0.0_0.25", "./iso_models/groupCard/groupCard_0.0_0.25", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.0_0.5", "./iso_models/groupCard/groupCard_0.0_0.5", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.0_0.75", "./iso_models/groupCard/groupCard_0.0_0.75", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.0_1.0", "./iso_models/groupCard/groupCard_0.0_1.0", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.25_0.5", "./iso_models/groupCard/groupCard_0.25_0.5", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.25_0.75", "./iso_models/groupCard/groupCard_0.25_0.75", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.25_1.0", "./iso_models/groupCard/groupCard_0.25_1.0", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.5_0.75", "./iso_models/groupCard/groupCard_0.5_0.75", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.5_1.0", "./iso_models/groupCard/groupCard_0.5_1.0", number_runs, stop_after_n_timeouts)
    eval_modelset("groupCard_0.75_1.0", "./iso_models/groupCard/groupCard_0.75_1.0", number_runs, stop_after_n_timeouts)

def feature_card_model_eval(number_runs, stop_after_n_timeouts):
    eval_modelset("featureCard_0.0_0.25", "./iso_models/featureCard/featureCard_0.0_0.25", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.0_0.5", "./iso_models/featureCard/featureCard_0.0_0.5", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.0_0.75", "./iso_models/featureCard/featureCard_0.0_0.75", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.0_1.0", "./iso_models/featureCard/featureCard_0.0_1.0", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.25_0.5", "./iso_models/featureCard/featureCard_0.25_0.5", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.25_0.75", "./iso_models/featureCard/featureCard_0.25_0.75", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.25_1.0", "./iso_models/featureCard/featureCard_0.25_1.0", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.5_0.75", "./iso_models/featureCard/featureCard_0.5_0.75", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.5_1.0", "./iso_models/featureCard/featureCard_0.5_1.0", number_runs, stop_after_n_timeouts)
    eval_modelset("featureCard_0.75_1.0", "./iso_models/featureCard/featureCard_0.75_1.0", number_runs, stop_after_n_timeouts)

def real_world_eval(number_runs):
    eval_modelset("real_world_models", "./real_world_models", number_runs, -1)

main()
