#!/usr/bin/env python3
"""
This script is used like a make file to build the Wheaton FSC web page
"""

import os
import sys
from pathlib import Path
from glob import glob
from jinja2 import Environment, PackageLoader, select_autoescape
import shutil
import shlex
from typing import NamedTuple
import subprocess
import argh


cwd = Path(__file__).absolute().parent
OUTDIR: Path = cwd / ".." / "wheatonfsc.github.io"
OUTDIR = OUTDIR.resolve()


if not OUTDIR.exists():
    answer = input(
        "Build directory does not exist. Would you like to clone the repository from github? (y/n)"
    )
    if answer.lower() in ("y", "yes"):
        import subprocess

        subprocess.call(
            shlex.split(
                "git clone https://github.com/WheatonFSC/wheatonfsc.github.io.git"
            )
        )
    else:
        print(f"Creating build directory: {OUTDIR}")
        OUTDIR.mkdir(exist_ok=True)

src_dir = cwd / "src"
template_dir = src_dir / "templates"


def html(template_name: str = "index"):
    """
    Transform an HTML template into a full HTML page
    """
    print(f"creating page {template_name}")

    template = template_name + ".html"

    if not (template_dir / template_dir).exists():
        template = template_name + ".html.jinja2"

    env = Environment(
        loader=PackageLoader("src", "templates"),
        autoescape=select_autoescape(["html", "xml"]),
    )

    outfile = Path(OUTDIR) / (template_name + ".html")
    outfile.write_text(env.get_template(template).render())

    # About page has a list of officers from officers.txt
    if template_name == "about":

        class Officer(NamedTuple):
            name: str
            position: str

        lines = (cwd / "src" / "officers.txt").read_text().splitlines()
        officers = [Officer(name, pos) for name, pos in zip(lines[::3], lines[1::3])]
        print(officers)

        outfile.write_text(env.get_template(template).render(officers=officers))


def static():
    """
    Remove static files directory from the build directory and copies it in from src
    """
    print("Copying static files")
    if (OUTDIR / "static").exists():
        shutil.rmtree(OUTDIR / "static")

    shutil.copytree(src_dir / "static", OUTDIR / "static")
    shutil.rmtree(OUTDIR / "static" / "photos")


def all():
    """
    Build all pages and copy over static content
    """
    # clean()
    html("index")
    html("about")
    html("membership")
    html("testing")
    html("volunteer")
    html("homerink")
    html("apparel")
    html("learntoskate")
    static()


def clean():
    """
    Remove the output directory (unless it is a GIT repository)
    """
    if (OUTDIR / ".git").exists:
        print(
            f"{OUTDIR} is a GIT repository.  Delete it manually if you really want it gone."
        )
    else:
        print(f"Cleaning output directory - {OUTDIR}")
        try:
            shutil.rmtree(OUTDIR)
        except:
            pass
        os.makedirs(OUTDIR, exist_ok=True)


if __name__ == "__main__":
    parser = argh.ArghParser("Make tool for Wheaton FSC web page")
    parser.add_commands([html, static, clean, all])
    parser.dispatch()