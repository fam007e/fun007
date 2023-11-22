import argparse
from translate import Translator
from multiprocessing import Pool

def translate_subtitle(args):
    input_file, output_file, target_language, i, line = args
    translator = Translator(to_lang=target_language)
    subtitle_text = line.strip()
    translated_text = translator.translate(subtitle_text)
    return i, f'{translated_text}\n'

def translate_srt(input_file, output_file, target_language='bn', num_processes=4):
    with open(input_file, 'r', encoding='utf-8') as infile:
        lines = infile.readlines()

    args_list = [(input_file, output_file, target_language, i, lines[i + 2]) for i in range(0, len(lines), 4)]

    with Pool(processes=num_processes) as pool:
        translated_lines = pool.map(translate_subtitle, args_list)

    for i, translated_line in translated_lines:
        lines[i + 2] = translated_line

    with open(output_file, 'w', encoding='utf-8') as outfile:
        outfile.writelines(lines)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Translate subtitles from English to Bangla.')
    parser.add_argument('input_file', help='Input .srt file path')
    parser.add_argument('output_file', help='Output .srt file path')
    args = parser.parse_args()

    translate_srt(args.input_file, args.output_file, target_language='bn')
